## Build Image
Build image using the command
```docker build -f Dockerfile -t pod/perf-jmeter:5.4.3.1a .```

This uses the Dockerfile which has instruction to download a specific version of jmeter from Jmeter website and build. By default rmi is disabled, so all the communication between the master and slave(s) are not secured. 

## Test Execution
1. Execute test using the following command
   * On windows, ```bash jmeterrunner.sh```
   * On Mac, ```./jmeterrunner.sh```
2. This creates a report folder in the base directory which contains a .csv file and a ```htmlreport``` folder containing the default jmeter html report
