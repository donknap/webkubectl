#!/bin/bash
set -e

if [ "${WELCOME_BANNER}" ]; then
    echo ${WELCOME_BANNER}
fi

# 解析命令行参数
while [[ $# -gt 0 ]]; do
  case $1 in
    --kube-config=*)
      kube_config="${1#*=}"
      ;;
    --api-server=*)
      server="${1#*=}"
      ;;
    --token=*)
      token="${1#*=}"
      ;;
    --extend-params=*)
      extend_params="${1#*=}"
      ;;
    --type=*)
      type="${1#*=}"
      ;;
    *)
      echo "无效的选项: $1" >&2
      exit 1
      ;;
  esac
  shift
done

mkdir -p /nonexistent
mount -t tmpfs -o size=${SESSION_STORAGE_SIZE} tmpfs /nonexistent
cd /nonexistent
cp /root/.bashrc ./
cp /etc/vim/vimrc.local .vimrc
echo 'source /opt/kubectl-aliases/.kubectl_aliases' >> .bashrc
echo -e 'PS1="> "\nalias ll="ls -la"' >> .bashrc
mkdir -p .kube

export HOME=/nonexistent
if [ "${type}" = "config" ]; then
    echo $kube_config| base64 -d > .kube/config
else
    echo `kubectl config set-credentials webkubectl-user --token=${token}` > /dev/null 2>&1
    echo `kubectl config set-cluster kubernetes --server=${server}` > /dev/null 2>&1
    echo `kubectl config set-context kubernetes --cluster=kubernetes --user=webkubectl-user` > /dev/null 2>&1
    echo `kubectl config use-context kubernetes` > /dev/null 2>&1
fi

# podId=api-7594d8f8dd-dlkhk&containerName=api&namespace=default&command=bash
if [[ -n $extend_params ]]; then
    # 使用IFS和for循环解析字符串并设置变量
    IFS='&' read -ra assignments <<< "$extend_params"
    for assignment in "${assignments[@]}"; do
    IFS='=' read -r varName varValue <<< "$assignment"
    declare "$varName"="$varValue"
    done

    if [[ -n $containerName ]]; then
        containerNameStr = "-c ${containerName} "
    fi

    if [[ -z "${command}" ]]; then
        command = "bash"
    fi

    extend_shell = "kubectl exec -it ${podId} -n ${namespace} ${containerNameStr}-- ${command}"
fi

if [ ${KUBECTL_INSECURE_SKIP_TLS_VERIFY} == "true" ];then
    {
        clusters=`kubectl config get-clusters | tail -n +2`
        for s in ${clusters[@]}; do
            {
                echo `kubectl config set-cluster ${s} --insecure-skip-tls-verify=true` > /dev/null 2>&1
                echo `kubectl config unset clusters.${s}.certificate-authority-data` > /dev/null 2>&1
            } || {
                echo err > /dev/null 2>&1
            }
        done
    } || {
        echo err > /dev/null 2>&1
    }
fi

chown -R nobody:nogroup .kube

export TMPDIR=/nonexistent

envs=`env`
for env in ${envs[@]}; do
    if [[ $env == GOTTY* ]];
    then
        unset ${env%%=*}
    fi
done

unset WELCOME_BANNER PPROF_ENABLED KUBECTL_INSECURE_SKIP_TLS_VERIFY SESSION_STORAGE_SIZE KUBECTL_VERSION

exec su -s /bin/bash nobody $extend_shell
