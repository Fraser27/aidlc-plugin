resource "aws_instance" "example" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
}
