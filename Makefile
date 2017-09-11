# this Makefile creates files which are needed for tests

KEYLEN=1024

.PHONY: all clean

all: server.crt client.p12 ca.crt ca.crl
clean:
	rm -f *.crt *.key *.crl *.csr *.txt *.old *.p12 *.attr *.srl

# create server key ############################################################
client.key:
	openssl genrsa -out $@ ${KEYLEN}
# create server certificate request
client.csr: client.key client.cf
	openssl req -new -key client.key -config client.cf -out $@
# create ca-signed server certificate
client.crt: client.csr ca.crt
	openssl x509 -req -in client.csr -out $@ \
	    -CAcreateserial -CAkey ca.key -CA ca.crt
# create pkcs12 version of the client key for import browser
client.p12: client.crt client.key
	openssl pkcs12 -export -clcerts -in client.crt -inkey client.key \
	    -passout "pass:" -out $@

# create server key ############################################################
server.key:
	openssl genrsa -out $@ ${KEYLEN}
# create server certificate request
server.csr: server.key server.cf
	openssl req -new -key server.key -config server.cf -out $@
# create ca-signed server certificate
server.crt: server.csr ca.crt
	openssl x509 -req -in server.csr -out $@ \
	    -CAcreateserial -CAkey ca.key -CA ca.crt

# create server key (for revoking) #############################################
server_revoke.key:
	openssl genrsa -out $@ ${KEYLEN}
# create server certificate request (for revoking)
server_revoke.csr: server_revoke.key server.cf
	openssl req -new -key server_revoke.key -config server.cf -out $@
# create ca-signed server certificate (for revoking)
server_revoke.crt: server_revoke.csr ca.crt
	openssl x509 -req -in server_revoke.csr -out $@ \
	    -CAcreateserial -CAkey ca.key -CA ca.crt

# create certificate authority #################################################
ca.key:
	openssl genrsa -out $@ ${KEYLEN}
ca.crt: ca.key ca.cf
	openssl req -new -x509 -key ca.key -config ca.cf -out $@

# create certificate revocation list ###########################################
ca.crl: ca.cf ca.key server_revoke.crt ca.txt
	openssl ca -config ca.cf -gencrl -revoke server_revoke.crt -out $@

ca.txt:
	touch $@
