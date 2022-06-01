#FROM bash:4.4
#COPY l_tcc_tools_p_2021.3.0.451_offline.sh /
#ENTRYPOINT ["l_tcc_tools_p_2021.3.0.451_offline.sh"]

FROM centos:centos7.9.2009
RUN mkdir /sample
WORKDIR /sample
COPY l_tcc_tools_p_2021.3.0.451_offline.sh /sample
RUN chmod +x ./l_tcc_tools_p_2021.3.0.451_offline.sh
RUN ./l_tcc_tools_p_2021.3.0.451_offline.sh -x -f ./
RUN chmod +x ./l_tcc_tools_p_2021.3.0.451_offline
RUN cd l_tcc_tools_p_2021.3.0.451_offline
RUN chmod +x ./l_tcc_tools_p_2021.3.0.451_offline/install.sh
RUN ./l_tcc_tools_p_2021.3.0.451_offline/install.sh --action=install --eula=accept --intel-sw-improvement-program-consent=no --silent
#RUN source ~/intel/tcc_tools/latest/env/vars.sh