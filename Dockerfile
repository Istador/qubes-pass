FROM  debian:10.6-slim  as  debian
FROM  fedora:33         as  fedora


###   base images                                                            ###
################################################################################
################################################################################
###   rpm                                                                    ###


FROM  fedora  as  rpm

RUN  dnf  check-update  ||  true
RUN  dnf  install  -y  make  findutils  fedora-packager

WORKDIR  /build/

COPY  ./  ./

RUN  make  rpm                                                       \
  && mv  ./qubes-pass-dom0-*.noarch.rpm     /qubes-pass-dom0.rpm     \
  && mv  ./qubes-pass-service-*.noarch.rpm  /qubes-pass-service.rpm  \
  && mv  ./qubes-pass-*.noarch.rpm          /qubes-pass-client.rpm   \
  && rm  -rf  /build/                                                \
;


###   rpm                                                                    ###
################################################################################
################################################################################
###   deb                                                                    ###


FROM  debian  as  deb

# backports for checkinstall
RUN  echo "deb http://deb.debian.org/debian buster-backports main" >>/etc/apt/sources.list  \
  &&  apt-get  update       \
  &&  apt-get  upgrade  -y  \
;

# software needed to build
RUN  apt-get  install  -y                    \
    checkinstall                             \
  && apt-get  clean  autoclean               \
  && apt-get  autoremove  -y                 \
  && rm  -rf  /var/lib/{apt,dpkg,cache,log}  \
;

WORKDIR  /build/

COPY  ./  ./


###   deb                                                                    ###
################################################################################
################################################################################
###   client-deb                                                             ###


FROM  deb  as  client-deb

ARG  VERSION
ARG  RELEASE

RUN  mkdir  -p  /usr/libexec/                     \
  && checkinstall                                 \
    --default                                     \
    --install=no                                  \
    --nodoc                                       \
    --pkgname=qubes-pass-client                   \
    --pkgversion="$VERSION"                       \
    --pkgrelease="$RELEASE"                       \
    --pkgarch="all"                               \
    --type=debian                                 \
    --requires="python3,qubes-core-agent-qrexec"  \
    make  install-client                          \
  && mv  $(ls /build/qubes-pass-client_${VERSION}-${RELEASE}_*.deb)  /install.deb  \
  && rm  -rf  /build/                             \
;


###   client-deb                                                             ###
################################################################################
################################################################################
###   service-deb                                                            ###


FROM  deb  as  service-deb

ARG  VERSION
ARG  RELEASE

RUN  mkdir  -p  /etc/qubes-rpc/                   \
  && checkinstall                                 \
    --default                                     \
    --install=no                                  \
    --nodoc                                       \
    --pkgname=qubes-pass-service                  \
    --pkgversion="$VERSION"                       \
    --pkgrelease="$RELEASE"                       \
    --pkgarch="all"                               \
    --type=debian                                 \
    --requires="pass,grep,coreutils,util-linux"   \
    make  install-service                         \
  && mv  $(ls /build/qubes-pass-service_${VERSION}-${RELEASE}_*.deb)  /install.deb  \
  && rm  -rf  /build/                             \
;


###   service-deb                                                            ###
################################################################################
################################################################################
###   out                                                                    ###


FROM  debian  as  out

COPY  --from=client-deb   /install.deb       /qubes-pass-client.deb
COPY  --from=service-deb  /install.deb       /qubes-pass-service.deb
COPY  --from=rpm          /qubes-pass-*.rpm  /


###   out                                                                    ###
################################################################################
