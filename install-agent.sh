#!/bin/bash

echo "Enter Temp Auth Token"
read token

# defaults
name=xedge-agent
data_path="${HOME}/.${name}-data"
staging=false
log=info
reinstall=false
pardon=""

function help() {
  echo $0 - Install xedge agent
  echo
  echo $0 [options] agent-version
  echo
  echo options:
  echo -h, --help   this
  echo -n, --name   set container name for agent
  echo --staging    configure agent to connect to xompass staging
  echo --debug      configure debug logging
  echo --reinstall  remove running container before running new instance
  echo --pardon     pardon single legacy xedge component with given name
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      help
      exit 0
      ;;
    -n|--name)
      shift
      if [[ $# -gt 0 ]]; then
        name=$1
      else
        echo "Name unspecified"
      fi
      shift
      ;;
    --staging)
      staging=true
      shift
      ;;
    --debug)
      log="info,xedge_agent=debug"
      shift
      ;;
    --reinstall)
      reinstall=true
      shift
      ;;
    --pardon)
      shift
      if [[ $# -gt 0 ]]; then
        pardon=$1
      else
        echo "Pardon unspecified"
      fi
      shift
      ;;
    *)
      break
      ;;
  esac
done

agent_version=$1

if $staging; then
  subdompost="-stg"
fi

# get rid of legacy if it exists
if [[ $(docker ps | grep xedge-device | wc -l) -gt 0 ]];
then
  echo "Detected instance of legacy xedge-device"
  xedge_device_id=$(docker inspect xedge-device | grep XEDGE_DEVICE_ID | sed 's/ *"XEDGE_DEVICE_ID=//g' | sed 's/", *//g')
  xedge_device_token=$(docker inspect xedge-device | grep XEDGE_DEVICE_TOKEN | sed 's/ *"XEDGE_DEVICE_TOKEN=//g' | sed 's/", *//g')

  echo "Stopping legacy xedge components"
  docker stop -t 1 xedge-device
  for id in $(docker ps -q)
  do
    inspect=$(docker inspect ${id})
    # Remove if xedge module/agent
    if [[ $(echo $inspect | grep xedge-type | wc -l) -gt 0 ]];
    then
      container_name=$(echo "$inspect" | \
        python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["Name"][1:])')
      if [[ "$container_name" != "$pardon" ]]; then
        docker stop -t 1 ${id}
      else
        echo "Pardoning $pardon"
      fi
    fi
  done
  echo "Removing legacy agent/modules"
  docker rm xedge-device
  for id in $(docker ps -qa)
  do
    inspect=$(docker inspect ${id})
    if [[ $(docker inspect $id | grep xedge-type | wc -l) -gt 0 ]];
    then
      container_name=$(echo "$inspect" | \
        python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["Name"][1:])')
      if [[ "$container_name" != "$pardon" ]]; then
        docker rm ${id}
      else
        echo "Pardoning $pardon"
      fi
    fi
  done
else
  if [[ -z ${XEDGE_DEVICE_ID} ]]; then
    echo XEDGE_DEVICE_ID must be set
    exit 1
  fi
  xedge_device_id=${XEDGE_DEVICE_ID}
  xedge_device_token=$(curl -G "https://api${subdompost}.xompass.com/api/DeviceTokens/findOne?access_token=$token" \
    --data-urlencode filter="{\"where\":{\"deviceId\":\"$XEDGE_DEVICE_ID\"}}" 2>/dev/null | \
    python3 -c 'import json,sys;d=json.load(sys.stdin);print("ERROR:",d["error"]["message"],file=sys.stderr) or sys.exit(1) if "error" in d else print(d["id"])')
fi


# create data path
mkdir -p $data_path

# connection config
cmdc_port=${CMDC_PORT:-443}
cmdc_https=${CMDC_HTTPS:-1}
if $staging; then
  cmdc_host=${CMDC_HOST:-cmdc-stg.xompass.com}
  xedge_sync=stg
else
  cmdc_host=${CMDC_HOST:-cmdc.xompass.com}
  xedge_sync=""
fi

if $reinstall; then
  docker stop -t1 $name && docker rm $name
fi

# should login?
[[ $(cat "$HOME/.docker/config.json"|grep xompassdevregistry.azurecr.io|wc -l)\
  -eq 0 ]] && temp_login=true || temp_login=false

if $temp_login; then
  echo "Logging in into docker registry"
  curl -G "https://bridge${subdompost}.xompass.com/api/Credentials" \
    --data "device_token=${xedge_device_token}" \
    --data-urlencode 'filter={"where":{"identifier":"xompass-dev-registry"}}' 2>/dev/null | \
  python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["content"]["registryAuth"]["password"])' | \
    docker login -u xompassdevregistry --password-stdin xompassdevregistry.azurecr.io
else
  echo "Already logged in docker registry"
fi

docker run \
  --name ${name} \
  -d \
  --restart always \
  -e RUST_LOG=$log \
  -e DOCKER_HOST_DATA_PATH=$data_path \
  -e XEDGE_DEVICE_ID=${xedge_device_id} \
  -e XEDGE_DEVICE_TOKEN=${xedge_device_token} \
  -e XEDGE_AGENT_ID=${xedge_device_id} \
  -e CMDC_HOST=$cmdc_host \
  -e CMDC_PORT=$cmdc_port \
  -e CMDC_HTTPS=$cmdc_https \
  -e XEDGE_SYNC=$xedge_sync \
  -l xedge-type=agent \
  -l xedge-agent-id=${xedge_device_id} \
  --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $data_path:/data \
  xompassdevregistry.azurecr.io/xedge-agent:$agent_version

if $temp_login; then
  echo "Logging out from docker registry"
  docker logout xompassdevregistry.azurecr.io
fi
