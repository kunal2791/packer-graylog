#Variables to define version
ELASTICSEARCH=5.1.1 
LOGSTASH=2.4.0
KIBANA=5.1.1
#Downloading java 8
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"
#install java8
sudo rpm -ivh jdk-8u131-linux-x64.rpm
#Downloading link for elasticsearch
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-$ELASTICSEARCH.rpm
#Downloading link for logstash
wget https://download.elastic.co/logstash/logstash/packages/centos/logstash-$LOGSTASH.noarch.rpm
#Downloading link for Kibana
wget https://artifacts.elastic.co/downloads/kibana/kibana-$KIBANA-x86_64.rpm
#intsall command for ELK RPM. 
sudo rpm -ivh logstash-$LOGSTASH.noarch.rpm 
sudo rpm -ivh elasticsearch-$ELASTICSEARCH.rpm
sudo rpm -ivh kibana-$KIBANA-x86_64.rpm
#install nginx and tools
sudo yum -y install nginx httpd-tools
#Move nginx.conf file to Nginx configuration directory.
sudo mv ~/conf/nginx.conf /etc/nginx/
#To provide password for Nginx user manually
#sudo htpasswd -c -b -d /etc/nginx/htpasswd.users kibanaadmin password
#To change network settings in elasticsearch conf file/*
sudo sed -i "s/#network.host: 192.168.0.1/network.host: 0.0.0.0/g" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/#http.port: 9200/http.port: 9200/g" /etc/elasticsearch/elasticsearch.yml
#Changing Kibana Configuration file.
sudo sed -i "s/#server.port/server.port/" /etc/kibana/kibana.yml
sudo sed -i "s/#server.host/server.host/" /etc/kibana/kibana.yml
sudo sed -i "s/#elasticsearch.url/elasticsearch.url/" /etc/kibana/kibana.yml
#Move Kibana web configuration from working location to nginx configuration directory.  
sudo mv ~/conf/kibana.conf /etc/nginx/conf.d/
#Restart ELK servives 
sudo service elasticsearch restart
sudo service kibana restart
sudo service logstash restart
sudo service nginx start
#To enable services
sudo chkconfig --add elasticsearch
sudo chkconfig --add kibana
sudo chkconfig --add logstash
sudo chkconfig nginx on
# Move logstash configuration file from working directory to logstash configuration directory
sudo mv ~/conf/*.conf /etc/logstash/conf.d/
sudo service logstash restart
sudo service nginx start
