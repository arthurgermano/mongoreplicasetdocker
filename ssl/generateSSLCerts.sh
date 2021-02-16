#!/bin/sh
TXT_LOG=" ----- "
CONFS_FILES_DIR="./confs/"
# the paths must match in docker-compose.yml file
# must match the file name of cluster.conf
MDB_NODE1_DIR="node_1"
MDB_NODE1_KEY="mdb_node_1.key"
MDB_NODE1_CSR="mdb_node_1.csr"
MDB_NODE1_CRT="mdb_node_1.crt"
MDB_NODE1_CNF="${CONFS_FILES_DIR}mdb_node1_CN.cnf"
# the paths must match in docker-compose.yml file
# must match the file name of cluster.conf
MDB_NODE2_DIR="node_2"
MDB_NODE2_KEY="mdb_node_2.key"
MDB_NODE2_CSR="mdb_node_2.csr"
MDB_NODE2_CRT="mdb_node_2.crt"
MDB_NODE2_CNF="${CONFS_FILES_DIR}mdb_node2_CN.cnf"
# the paths must match in docker-compose.yml file
# must match the file name of cluster.conf
MDB_NODE_ARB_DIR="node_arbiter"
MDB_NODE_ARB_KEY="mdb_node_arbiter.key"
MDB_NODE_ARB_CSR="mdb_node_arbiter.csr"
MDB_NODE_ARB_CRT="mdb_node_arbiter.crt"
MDB_NODE_ARB_CNF="${CONFS_FILES_DIR}mdb_node_arbiter_CN.cnf"
# must match the file name of cluster.conf
MDB_CA_DIR="CA"
MDB_CA_KEY="mdb_root_CA.key"
MDB_CA_CRT="mdb_root_CA.crt"
MDB_CA_SRL="mdb_root_CA.srl"
MDB_CA_CNF="${CONFS_FILES_DIR}mdb_root_CA.cnf"
MDB_PASS_PHRASE_CA="mdb_my_custom_passphrase_security"
# must match the file name of cluster.conf
MDB_FINAL_KEYCERT_PEM="mdb_nodes_keycert.pem"
MDB_CLIENT_DIR="serverclient"
MDB_CLIENT_KEY="mdb_client.key"
MDB_CLIENT_CSR="mdb_client.csr"
MDB_CLIENT_CRT="mdb_client.crt"
MDB_CLIENT_PEM="mdb_client.pem"
MDB_CLIENT_CN_CNF="${CONFS_FILES_DIR}mdb_client_CN.cnf"
# param order
# DIR         ----- $1 - $X_DIR
# FILE        ----- $2 - $FILEVAR_NAME
move_files() {
mkdir $1 2> /dev/null
printf "Moving $2 to ./$1/$2 $TXT_LOG \n"
mv ./$2 ./$1/$2
}
# param order
# DIR         ----- $1 - $X_DIR
# FILE        ----- $2 - $FILEVAR_NAME
copy_files() {
mkdir $1 2> /dev/null
printf "Copying $2 to ./$1/$2 $TXT_LOG \n"
cp ./$2 ./$1/$2
}
# param order
# DIR         ----- $1 - $MDB_NODEX_DIR
# NODE .key file  ----- $2 - $MDB_NODEX_KEY
# NODE .csr file  ----- $3 - $MDB_NODEX_CSR
# NODE .cnf file  ----- $4 - $MDB_NODEX_CNF
# MDB CA .crt file  ----- $5 - $MDB_CA_CRT
# MDB CA .key file  ----- $6 - $MDB_CA_KEY
# NODE .crt file  ----- $7 - $MDB_NODEX_CRT
gen_node_keycerts(){
printf "\nSTARTING $1 Certificates $TXT_LOG \n"
mkdir $1 2> /dev/null
printf "Generating $1 - KEY and CSR files $TXT_LOG\n"
openssl genrsa -des3 -out $2 -passout pass:"$MDB_PASS_PHRASE_CA" 4096
printf "\nGenerating $1 - CRT file $TXT_LOG\n"
openssl req -new -config $4 -key $2 -passin pass:"$MDB_PASS_PHRASE_CA" -out $3 -config $4
openssl x509 -req -days 365 -in $3 -CA $5 -CAkey $6 -CAcreateserial -passin pass:"$MDB_PASS_PHRASE_CA" -out $7
printf "\nGenerating $1 - PEM file $TXT_LOG\n"
cat $2 $7 > $MDB_FINAL_KEYCERT_PEM
move_files $1 $2
move_files $1 $3
move_files $1 $7
move_files $1 $MDB_FINAL_KEYCERT_PEM
copy_files $1 $5
printf "\nFINISHED $1 $TXT_LOG\n"
}
openssl rand -writerand .rnd
printf "STARTING SCRIPT $TXT_LOG\n\n"
openssl genrsa -des3 -out $MDB_CA_KEY -passout pass:"$MDB_PASS_PHRASE_CA" 4096
printf "Root CA key OK $TXT_LOG \n"
openssl req -x509 -new -key $MDB_CA_KEY -sha256 -passin pass:"$MDB_PASS_PHRASE_CA" -days 720 -out $MDB_CA_CRT -config $MDB_CA_CNF
printf "Root CA crt OK $TXT_LOG \n"
printf "FINISHED CA CERTIFICATE $TXT_LOG \n"
gen_node_keycerts $MDB_NODE1_DIR $MDB_NODE1_KEY $MDB_NODE1_CSR $MDB_NODE1_CNF $MDB_CA_CRT $MDB_CA_KEY $MDB_NODE1_CRT
gen_node_keycerts $MDB_NODE2_DIR $MDB_NODE2_KEY $MDB_NODE2_CSR $MDB_NODE2_CNF $MDB_CA_CRT $MDB_CA_KEY $MDB_NODE2_CRT
gen_node_keycerts $MDB_NODE_ARB_DIR $MDB_NODE_ARB_KEY $MDB_NODE_ARB_CSR $MDB_NODE_ARB_CNF $MDB_CA_CRT $MDB_CA_KEY $MDB_NODE_ARB_CRT
printf "Generating client access certificates key and cert $TXT_LOG \n"
openssl req -new -out $MDB_CLIENT_CSR -keyout $MDB_CLIENT_KEY -passout pass:"$MDB_PASS_PHRASE_CA" -config $MDB_CLIENT_CN_CNF
printf "Signing client access certificates $TXT_LOG \n"
openssl x509 -req -in $MDB_CLIENT_CSR -CA $MDB_CA_CRT -CAkey $MDB_CA_KEY -passin pass:"$MDB_PASS_PHRASE_CA" -out $MDB_CLIENT_CRT
printf "Generating client PEM file $TXT_LOG \n"
cat $MDB_CLIENT_KEY $MDB_CLIENT_CRT > $MDB_CLIENT_PEM
move_files $MDB_CLIENT_DIR $MDB_CLIENT_CSR
move_files $MDB_CLIENT_DIR $MDB_CLIENT_KEY
move_files $MDB_CLIENT_DIR $MDB_CLIENT_CRT
move_files $MDB_CLIENT_DIR $MDB_CLIENT_PEM
copy_files $MDB_CLIENT_DIR $MDB_CA_CRT
move_files $MDB_CA_DIR $MDB_CA_KEY
move_files $MDB_CA_DIR $MDB_CA_CRT
move_files $MDB_CA_DIR $MDB_CA_SRL
printf "FINISHED $1 $TXT_LOG\n"