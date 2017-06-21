#!/usr/bin/env bash

ORIG_PATH=$PWD
cd test/dummy
rails generate scaffold some_item name:string item_type:string quantity:integer is_used:boolean last_received:date
rake db:migrate
rails server
rake db:rollback
rails destroy scaffold some_item
cd $ORIG_PATH
