#!/bin/bash -x

# Fail this script if any command fails
set -e

cd
exec ./ets enrollmentFilePath=/bootstrapot2/exstreamcs.json \
	appName="$ETS_APP_NAME" \
	appVersion="$ETS_APP_VERSION" \
	envOtdsClientId=OTDS_OAUTH2_CLIENTID \
	envOtdsClientSecret=OTDS_OAUTH2_CLIENT_SECRET \
	excs.appName="$ETS_APP_NAME" \
	excs.appDisplayName="$ETS_APP_DISPLAY_NAME" \
	excs.appVersion="$ETS_APP_VERSION" \
	excs.url="$EXSTREAM_URL_FRONTEND_DAS_URL"
