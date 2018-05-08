#!/bin/bash
cd /media/david/Drive/Binder/Csc_336/Assignments/Group\ Project/Code/sql-crypto-data-filler
mysql -u root -p23058319 < firstStep.sql
npm start &
sleep 3
mysql -u root -p23058319 < lastStep.sql