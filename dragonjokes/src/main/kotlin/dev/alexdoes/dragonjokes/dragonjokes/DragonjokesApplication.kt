package dev.alexdoes.dragonjokes.dragonjokes

import org.springframework.boot.CommandLineRunner
import org.springframework.boot.autoconfigure.EnableAutoConfiguration
import org.springframework.boot.autoconfigure.SpringBootApplication
import org.springframework.boot.context.properties.ConfigurationProperties
import org.springframework.boot.context.properties.EnableConfigurationProperties
import org.springframework.boot.runApplication
import org.springframework.context.annotation.Bean
import org.springframework.context.annotation.Configuration
import org.springframework.stereotype.Component
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController
import software.amazon.awssdk.auth.credentials.DefaultCredentialsProvider
import software.amazon.awssdk.regions.Region
import software.amazon.awssdk.services.dynamodb.DynamoDbClient;
import software.amazon.awssdk.services.dynamodb.model.*
import java.util.*


@SpringBootApplication
@EnableConfigurationProperties
class DragonjokesApplication

fun main(args: Array<String>) {
    runApplication<DragonjokesApplication>(*args)
}

@Configuration
class Beans {
    @Bean
    fun dynamoDb() = DynamoDbClient.builder()
            .region(Region.EU_CENTRAL_1)
            .credentialsProvider(DefaultCredentialsProvider.create())
            .build()
}

@Component
@ConfigurationProperties("config")
class Config {
    lateinit var tableName: String
    var jokes: Collection<String> = emptyList()
}

@Component
class InitialIngester(val client: DynamoDbClient, val config: Config) : CommandLineRunner {
    override fun run(vararg args: String?) {
        val count = client.scan(ScanRequest.builder()
                .tableName(config.tableName)
                .select("COUNT")
                .build()).count()
        if (count == 0 && config.jokes.isNotEmpty()) {
            val random = Random()
            config.jokes.asSequence()
                    .map {
                        mapOf<String, AttributeValue>(
                                Pair("jokeId", AttributeValue.builder().n(random.nextInt().toString()).build()),
                                Pair("joke", AttributeValue.builder().s(it).build()))
                                .let { item -> WriteRequest.builder().putRequest { it.item(item) }.build() }
                    }
                    .toList()
                    .also {
                        client.batchWriteItem(BatchWriteItemRequest.builder()
                                .requestItems(mapOf(Pair(config.tableName, it)))
                                .build())
                    }

        }

    }

}

@RestController
class Api(val client: DynamoDbClient, val config: Config) {

    @GetMapping("jokes")
    fun getJokes(): List<String> {
        return client.scan(ScanRequest.builder()
                .tableName(config.tableName)
                .select("ALL_ATTRIBUTES")
                .build())
                .items()
                .map { it["joke"]?.s().toString() }

    }
}