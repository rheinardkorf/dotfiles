## Current Temp
alias office_temp="curl -L -X POST 'https://px1.tuyaus.com/homeassistant/skill' -H 'name: Discovery' -H 'namespace: discovery' -H 'payloadVersion: 1' -H 'Content-Type: application/json' -H 'Authorization: Bearer EUheu1589957783887Eo7acwM9Kba8kFD' --data-raw '{\"header\": {\"name\": \"state\",\"namespace\": \"query\",\"payloadVersion\": 1},\"payload\": {\"accessToken\": \"EUheu1589957783887Eo7acwM9Kba8kFD\",\"devId\": \"04010761a4e57c99807f\"}}' | jq '.payload.data.current_temperature' | awk {'print $1,\"°C\"'}"

