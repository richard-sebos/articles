- So far we have
* Setup AIDE to monitor for files changes, a indicator of a intruder
* Signed the results of AIDE database for system integrity
* Chain and hide the logs from AIDE to see if they hav been tampered with
- Next we want to hide the fact that we are running AIDE

## Why hide AIDE
- To hide or not to hide is a hard question to answer
- I one side, if an intrude see AIDE being use, they will realized their actions could be monitored but  will that make them more careful
- If they don't know it being used, it maybe easier to chech the intruder
- It is a hard call either way
- If not AIDE, sooner or later you may want to hide what is running in systemd.
