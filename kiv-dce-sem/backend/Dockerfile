#
# Simple backend demo server image
#

FROM centos:centos7

RUN yum -q -y install python3
RUN pip3 install flask

COPY python /opt/backend

CMD /usr/bin/python3 /opt/backend/simple-backend.py

# EOF
