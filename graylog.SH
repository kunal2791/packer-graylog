#!/bin/bash
Java (){
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.rpm"
#install java8
sudo yum localinstall -y jdk-8u131-linux-x64.rpm
}

MongoDB (){
# Install mongodb
(
cat <<'EOF'
[mongodb-enterprise]
name=MongoDB Enterprise Repository
baseurl=https://repo.mongodb.com/yum/amazon/2013.03/mongodb-enterprise/3.4/$basearch/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-3.4.asc
enabled=1
EOF
) | sudo tee /etc/yum.repos.d/mongodb.repo
echo "Install MongoDB"
sudo yum update -y
sudo yum install -y mongodb-enterprise
echo "Starting  MongoDB"
sudo service mongod start
sudo chkconfig --add mongod
}
mount_ebs (){
sudo mkfs.ext4 -F /dev/sdb
sudo mkdir /grayvolume
sudo mount /dev/sdb /var/lib/elasticsearch
echo -e "/dev/sdb /var/lib/elasticsearch ext4 defaults,nofail 0 2" | sudo tee --append /etc/fstab
sudo mount -a
sudo chown elasticsearch:elasticsearch -r /var/lib/elasticsearch/
}
Elasticsearch (){
echo "Installing ElasticSearch"
echo Install ES
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.1.1.rpm
sudo rpm -ivh elasticsearch-5.1.1.rpm
echo "starting Elasticsearch"
sudo service elasticsearch start
echo "ES Configuration Started"
#sudo sed -i "s/#network.host: 192.168.0.1/network.host: 0.0.0.0/g" /etc/elasticsearch/elasticsearch.yml
#sudo sed -i "s/#discovery.zen.minimum_master_nodes: 3/discovery.zen.minimum_master_nodes: false/g" /etc/elasticsearch/elasticsearch.yml
sudo chkconfig --add elasticsearch
echo "ES configuration completed"
}

graylog (){
echo "installing Graylog server"
sudo rpm -Uvh https://packages.graylog2.org/repo/packages/graylog-2.3-repository_latest.rpm
sudo yum install -y graylog-server
echo "graylog-server installed"
echo "starting graylog-server"
sudo service graylog-server start
sudo chkconfig --add graylog-server
echo "starting with graylog configuration"
}
configuration (){
secret_pass="$(echo -n password | sha256sum |awk '{print $1}')"
sudo sed -i "s/password_secret =/password_secret = $secret_pass /g" /etc/graylog/server/server.conf
sudo sed -i "s/root_password_sha2 =/root_password_sha2 = $secret_pass /g" /etc/graylog/server/server.conf
sudo sed -i "s/elasticsearch_shards = 4/elasticsearch_shards = 1/g" /etc/graylog/server/server.conf
IPADDY=`curl http://169.254.169.254/latest/meta-data/local-ipv4`
mypubip="$(dig +short myip.opendns.com @resolver1.opendns.com)"
sudo sed -i -e 's|rest_listen_uri = http://127.0.0.1:9000/api/|#rest_listen_uri = http://$IPADDY:9000/api/|' /etc/graylog/server/server.conf
echo -e "web_listen_uri = http://$IPADDY:9000/" | sudo tee --append /etc/graylog/server/server.conf >> /dev/null
echo -e "rest_listen_uri = http://$IPADDY:9000/api/" | sudo tee --append /etc/graylog/server/server.conf >> /dev/null
#echo -e "rest_transport_uri = http://$mypubip:9000/api/" | sudo tee --append /etc/graylog/server/server.conf >> /dev/null
echo ${graylog_url}
echo "rest_transport_uri = http://${graylog_url}/api/" | sudo tee --append /etc/graylog/server/server.conf 
sudo chown -R elasticsearch.elasticsearch /var/lib/elasticsearch
}
service (){
sudo service graylog-server restart
sudo service elasticsearch restart
sudo service mongod restart
sudo chkconfig --add elasticsearch
sudo chkconfig --add graylog-server
sudo chkconfig --add mongod
}
rsyslog (){
echo -e "*.* @$IPADDY:1514;RSYSLOG_SyslogProtocol23Format" | sudo tee --append /etc/rsyslog.conf >> /dev/null
sudo service rsyslog restart
echo "we are all done"
echo "Browse to http://$mypubip:9000"
}
#ec2 Linux disk & memory collector script
disk () {
sudo yum install -y perl-Switch perl-DateTime perl-Sys-Syslog perl-LWP-Protocol-https
curl http://aws-cloudwatch.s3.amazonaws.com/downloads/CloudWatchMonitoringScripts-1.2.1.zip -O
unzip CloudWatchMonitoringScripts-1.2.1.zip
rm CloudWatchMonitoringScripts-1.2.1.zip
echo -e "*/5 * * * * ~/aws-scripts-mon/mon-put-instance-data.pl --mem-util --disk-space-avail --disk-path=/ --from-cron" | sudo tee --append /var/spool/cron/ec2-user >> /dev/null
}
mount_ebs
Java
MongoDB
Elasticsearch
graylog
configuration
service
rsyslog
