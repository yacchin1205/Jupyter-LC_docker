# base-demo-lab 2024-11-12
#FROM niicloudoperation/notebook@sha256:96a6725cf6eab085c3330189591476839f0efaaaf5359e82591656510cbbcae2
FROM yacchin1205/notebook@sha256:95782d693a0410f2fff453ab0b57e8c8f4cc54d1088bd90ab5216bd36e43f6f2

USER root

ADD sample-notebooks /home/$NB_USER
RUN chown jovyan:users -R /home/$NB_USER/

USER $NB_USER
