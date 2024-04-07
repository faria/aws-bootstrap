#!/bin/bash -xe
source /home/ec2-user/.bash_profile
cd /home/ec2-user/app/release
# run the script defined in scripts.start in package.json
npm run start