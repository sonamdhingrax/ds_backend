import json
import time

def lambda_handler(event, context):
    # This maybe handy when creating tests
    drift = 0

    #Get Server time and timezone
    server_epoch_time = int(time.time()) + drift
    server_time_zone = time.tzname[0]

    # output 
    time_information = {
        "server_epoch_time": server_epoch_time,
        "server_time_zone": server_time_zone
    }

    return {
        'statusCode': 200,
        'body': json.dumps(time_information)
    }
