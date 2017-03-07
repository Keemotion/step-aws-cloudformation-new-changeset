#!/bin/bash -ex

if [ ! -n "$AWS_ACCESS_KEY_ID" ]; then
  if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_AWS_ACCESS_KEY_ID" ]; then
    error "Please specify an AWS_ACCESS_KEY_ID"
    return 1
  else
    export AWS_ACCESS_KEY_ID="$WERCKER_AWS_CLOUDFORMATION_CHANGESET_AWS_ACCESS_KEY_ID"
  fi
fi

if [ ! -n "$AWS_SECRET_ACCESS_KEY" ]; then
  if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_AWS_SECRET_ACCESS_KEY" ]; then
    error "Please specify an AWS_SECRET_ACCESS_KEY"
    return 1
  else
    export AWS_SECRET_ACCESS_KEY="$WERCKER_AWS_CLOUDFORMATION_CHANGESET_AWS_SECRET_ACCESS_KEY"
  fi
fi

if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_REGION" ]; then
  error "Please specify your region."
fi

if [ ! -n "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_STACK" ]; then
  error "Please specify your stack name."
fi

# First make sure aws is installed
if ! type aws &> /dev/null ; then
  info "awscli is not installed, trying to install through pip"
  if ! type pip &> /dev/null ; then
    fail "pip not found, make sure you have pip or awscli installed"
  else
    info "pip is available"
    debug "pip verstion is: $(pip --version)"
    pip install awscli
  fi
else
  info "awscli is available"
  debug "awscli version: $(aws --version)"
fi

declare -x WERCKER_AWS_CLOUDFORMATION_CHANGESET_TEMPLATE_ARG="--template-body file://$WERCKER_AWS_CLOUDFORMATION_CHANGESET_TEMPLATE_PATH"

if [ -n "${WERCKER_AWS_CLOUDFORMATION_CHANGESET_CAPABILITIES:+1}" ]; then
  declare -x WERCKER_AWS_CLOUDFORMATION_CHANGESET_CAPABILITY_ARG="--capabilities $WERCKER_AWS_CLOUDFORMATION_CHANGESET_CAPABILITIES"
else
  declare -x WERCKER_AWS_CLOUDFORMATION_CHANGESET_CAPABILITY_ARG=""
fi

echo aws --region "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_REGION" cloudformation create-change-set \
  --stack-name "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_STACK" \
  $WERCKER_AWS_CLOUDFORMATION_CHANGESET_TEMPLATE_ARG \
  --parameters $WERCKER_AWS_CLOUDFORMATION_CHANGESET_PARAMETERS \
  $WERCKER_AWS_CLOUDFORMATION_CHANGESET_CAPABILITY_ARG \
  --change-set-name $WERCKER_AWS_CLOUDFORMATION_CHANGESET_CHANGESET

CHANGESETSTATUS="CREATE_IN_PROGRESS"

if [ "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_WAIT" == "true" ]; then
  while [ "$CHANGESETSTATUS" == *CREATE_IN_PROGRESS ]; do
    TMPRESULT=$(aws --region "$WERCKER_AWS_CLOUDFORMATION_CHANGESET_REGION" cloudformation list-change-set --stack-name $WERCKER_AWS_CLOUDFORMATION_CHANGESET_STACK)
    CHANGESETSTATUS=$(echo "$TMPRESULT" | python -c 'import json,sys,os;obj=json.load(sys.stdin);changeset=[s["Status"] for s in obj["StackSummaries"] if s["ChangeSetName"] == os.environ.get("WERCKER_AWS_CLOUDFORMATION_CHANGESET")];print changeset[0]')
    echo "$CHANGESETSTATUS"
    if [ "$CHANGESETSTATUS" == *CREATE_COMPLETE ]; then
      return 0
    elif [ "$CHANGESETSTATUS" == *FAILED ]; then
      return 1
    fi
    info "Waiting for launch, checking again in 10 seconds..."
    sleep 10
  done
fi
