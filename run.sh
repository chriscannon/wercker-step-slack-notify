#!/bin/bash


if [ ! -n "$WERCKER_SLACK_NOTIFY_SUBDOMAIN" ]; then
# fail causes the wercker interface to display the error without the need to
# expand the step
  fail 'Please specify the subdomain property'
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_TOKEN" ]; then
  fail 'Please specify token property'
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_CHANNEL" ]; then
  fail 'Please specify a channel'
fi

if [[ $WERCKER_SLACK_NOTIFY_CHANNEL == \#* ]]; then
  fail "Please specify the channel without the '#'"
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_FAILED_MESSAGE" ]; then
  if [ ! -n "$DEPLOY" ]; then
    export WERCKER_SLACK_NOTIFY_FAILED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_BUILD_URL|build> of $WERCKER_GIT_BRANCH by $WERCKER_STARTED_BY failed."
  else
    export WERCKER_SLACK_NOTIFY_FAILED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_DEPLOY_URL|deploy> of $WERCKER_GIT_BRANCH to $WERCKER_DEPLOYTARGET_NAME by $WERCKER_STARTED_BY failed."
  fi
fi

if [ ! -n "$WERCKER_SLACK_NOTIFY_PASSED_MESSAGE" ]; then
  if [ ! -n "$DEPLOY" ]; then
    export WERCKER_SLACK_NOTIFY_PASSED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_BUILD_URL|build> of $WERCKER_GIT_BRANCH by $WERCKER_STARTED_BY passed."
  else
    export WERCKER_SLACK_NOTIFY_PASSED_MESSAGE="$WERCKER_APPLICATION_OWNER_NAME/$WERCKER_APPLICATION_NAME: <$WERCKER_DEPLOY_URL|deploy of $WERCKER_GIT_BRANCH> to $WERCKER_DEPLOYTARGET_NAME by $WERCKER_STARTED_BY passed."
  fi
fi

if [ "$WERCKER_RESULT" = "passed" ]; then
  export WERCKER_SLACK_NOTIFY_MESSAGE="$WERCKER_SLACK_NOTIFY_PASSED_MESSAGE"
else
  export WERCKER_SLACK_NOTIFY_MESSAGE="$WERCKER_SLACK_NOTIFY_FAILED_MESSAGE"
fi


if [ "$WERCKER_SLACK_NOTIFY_ON" = "failed" ]; then
  if [ "$WERCKER_RESULT" = "passed" ]; then
    echo "Skipping.."
    return 0
  fi
fi

json="{\"channel\": \"#$WERCKER_SLACK_NOTIFY_CHANNEL\", \"text\": \"$WERCKER_SLACK_NOTIFY_MESSAGE\"}"

RESULT=`curl -s -d "payload=$json" "https://$WERCKER_SLACK_NOTIFY_SUBDOMAIN.slack.com/services/hooks/incoming-webhook?token=$WERCKER_SLACK_NOTIFY_TOKEN" --output $WERCKER_STEP_TEMP/result.txt -w "%{http_code}"`

if [ "$RESULT" = "500" ]; then
  if grep -Fqx "No token" $WERCKER_STEP_TEMP/result.txt; then
    fail "No token is specified."
  fi

  if grep -Fqx "No hooks" $WERCKER_STEP_TEMP/result.txt; then
    fail "No hook can be found for specified subdomain/token"
  fi

  if grep -Fqx "Invalid channel specified" $WERCKER_STEP_TEMP/result.txt; then
    fail "Could not find specified channel for subdomain/token."
  fi

  if grep -Fqx "No text specified" $WERCKER_STEP_TEMP/result.txt; then
    fail "No text specified."
  fi

  # Unhandled error
  # fail <$WERCKER_STEP_TEMP/result.txt
fi

if [ "$RESULT" = "404" ]; then
  fail "Subdomain or token not found."
fi
