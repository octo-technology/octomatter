#!/usr/bin/python
# Copyright (c) 2020, Remi REY
# GNU General Public License v3.0+ (see COPYING or https://www.gnu.org/licenses/gpl-3.0.txt)

from __future__ import absolute_import, division, print_function
__metaclass__ = type


ANSIBLE_METADATA = {'status': ['preview'],
                    'supported_by': 'community',
                    'metadata_version': '1.1'}

DOCUMENTATION = '''
---
module: rds_cluster_info
short_description: obtain information about one RDS cluster
description:
  - Obtain information about one RDS cluster.
options:
  db_cluster_identifier:
    description:
      - The RDS cluster's unique identifier.
    required: false
    aliases:
      - id
    type: str
requirements:
    - "python >= 2.7"
    - "boto3"
author:
    - "Will Thames (@willthames)"
    - "Michael De La Rue (@mikedlr)"
extends_documentation_fragment:
- amazon.aws.aws
- amazon.aws.ec2

'''

EXAMPLES = '''
# Get information about an instance
- rds_cluster_info:
    db_cluster_identifier: "new-database"
  register: new_database_info
'''

RETURN = '''
cluster:
    TODO
'''

from ansible_collections.amazon.aws.plugins.module_utils.aws.core import AnsibleAWSModule
from ansible_collections.amazon.aws.plugins.module_utils.ec2 import AWSRetry


try:
    import botocore
except ImportError:
    pass  # handled by AnsibleAWSModule


def main():
    argument_spec = dict(
        db_cluster_identifier=dict(type='str', aliases=['id'])
    )

    module = AnsibleAWSModule(
        argument_spec=argument_spec,
        supports_check_mode=True,
    )
    conn = module.client('rds', retry_decorator=AWSRetry.jittered_backoff(retries=10))
    response = conn.describe_db_clusters(
        DBClusterIdentifier=module.params["db_cluster_identifier"],
    )
    module.exit_json(cluster=response["DBClusters"][0])


if __name__ == '__main__':
    main()
