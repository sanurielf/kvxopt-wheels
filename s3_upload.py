# -*- coding: utf-8 -*-
# @Author: Uriel Sandoval
# @Date:   2021-06-19 10:06:43
# @Last Modified by:   Uriel Sandoval
# @Last Modified time: 2021-06-19 11:07:28
import boto3
from os import environ as ENV, path
from sys import argv

def upload(file):

    s3 = boto3.resource('s3',
        endpoint_url = 'https://s3.us-west-1.wasabisys.com',
        aws_access_key_id = ENV['WASABI_KEY_ID'], 
        aws_secret_access_key = ENV['WASABI_ACCESS_KEY']
    )


    s3.meta.client.upload_file(file, 'kvxoptwheels', path.basename(file))



if __name__ == '__main__':
    upload(argv[1])
    