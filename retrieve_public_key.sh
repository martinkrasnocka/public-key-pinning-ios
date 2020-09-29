openssl s_client -connect github.com:443 -showcerts < /dev/null | openssl x509 -outform der > server_cert.der
openssl x509 -inform der -in server_cert.der -pubkey -noout > server_cert_public_key.pem
cat server_cert_public_key.pem | openssl rsa -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
