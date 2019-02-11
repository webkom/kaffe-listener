# KaffeListener

This repo connects to our MQTT server, listening 1) for power measurements from a socket connected to our moccamaster, and 2) for card scannings from a card reader placed next to the moccamaster. Whenever coffee is brewed, the script estimates the volume by checking how long the brew took, and then sends a message to slack with who brewed and how much they brewed. The information about the brew is also broadcast back to MQTT for other consumers, where it is picked up by another script that stores the historical data in influxDB.

