
resource "aws_dynamodb_table" "app_jokes" {
  name         = "jokes-${local.stack}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "jokeId"

  attribute {
    name = "jokeId"
    type = "N"
  }
}