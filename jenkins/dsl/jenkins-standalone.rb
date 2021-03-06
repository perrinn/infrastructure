#!/usr/bin/env ruby

require 'bundler/setup'
require 'cloudformation-ruby-dsl/cfntemplate'

template do

    value AWSTemplateFormatVersion: '2010-09-09'
    value Description: 'Jenkins Full Stack'

    parameter 'AccessCidr',
        Type: 'String',
        AllowedPattern: '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})',
        ConstraintDescription: 'must be a valid IP CIDR range of the form x.x.x.x/x.',
        Description: 'IP Range or Address allowed access to the instance',
        MaxLength: '18',
        MinLength: '9'

    parameter 'AccessSecurityGroup',
        Type: 'String',
        Description: 'Security Group ID for existing Access Control Group'

    parameter 'AccessSubnet',
        Type: 'String',
        AllowedPattern: 'subnet-[a-z0-9]{8}',
        ConstraintDescription: 'Must be a valid subnet ID',
        Description: 'Subnet for the Access (Public) interface',
        MaxLength: '15',
        MinLength: '15',
        Default: 'subnet-e96a25c1'

    parameter 'AdminCidr',
        Type: 'String',
        AllowedPattern: '(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})',
        ConstraintDescription: 'must be a valid IP CIDR range of the form x.x.x.x/x.',
        Description: 'IP Range or Address allowed administrative access to the instance',
        MaxLength: '18',
        MinLength: '9',
        Default: '1.129.96.248/32'

    parameter 'AdminSecurityGroup',
        Type: 'String',
        Description: 'Security Group ID for existing Access Control Group'

    parameter 'AdminSubnet',
        Type: 'String',
        AllowedPattern: 'subnet-[a-z0-9]{8}',
        ConstraintDescription: 'Must be a valid subnet ID',
        Description: 'Subnet for the Admin interface',
        MaxLength: '15',
        MinLength: '15',
        Default: 'subnet-e96a25c1'

    parameter 'AZ',
        Type: 'String',
        Description: 'Availability Zone to place instance in'

    parameter 'CfnBucket',
        Type: 'String',
        Default: 'perrinn-cfn'

    parameter 'ServerAmi',
        Type: 'String',
        AllowedPattern: 'ami-[a-z0-9]{8}',
        MaxLength: '12',
        MinLength: '12',
        Default: 'ami-fb91b9ec'

    parameter 'InstanceType',
        Type: 'String',
        Description: 'Instance Size for this machine',
        Default: 't2.micro'

    parameter 'KeyName',
        Type: 'AWS::EC2::KeyPair::KeyName',
        ConstraintDescription: 'Must be a valid, existing Key Pair'

    parameter 'NewRelicKey',
        Type: 'String',
        Default: '1234'

    parameter 'Product',
        Type: 'String',
        Default: 'jenkins'

    parameter 'VpcId',
        Type: 'String',
        AllowedPattern: 'vpc-[a-z0-9]{8}',
        ConstraintDescription: 'Must be a valid, existing VPC',
        MaxLength: '12',
        MinLength: '12',
        Default: 'vpc-e47c9481'

    parameter 'ZoneName',
        Type: 'String',
        Default: 'perrinnapp.net'

    condition 'AccessSecCond',
        equal(ref('AccessSecurityGroup'), '')

    condition 'AdminSecCond',
        equal(ref('AdminSecurityGroup'), '')

    condition 'Register53',
        not_equal(ref('ZoneName'), '')
        

    resource 'AdminSecurity', Condition: 'AdminSecCond', Type: 'AWS::EC2::SecurityGroup', Properties: {
        GroupDescription: 'Access to management port on Jenkins Host',
        VpcId: ref('VpcId'),
        SecurityGroupIngress: [
            {
                CidrIp: ref('AdminCidr'),
                IpProtocol: 'tcp',
                FromPort: '22',
                ToPort: '22'
            }
        ]
    }

    resource 'AccessSecurity', Condition: 'AccessSecCond', Type: 'AWS::EC2::SecurityGroup', Properties: {
        GroupDescription: 'Access to inbount port(s) on Jenkins Host',
        VpcId: ref('VpcId'),
        SecurityGroupIngress: [
            {
                CidrIp: ref('AccessCidr'),
                IpProtocol: 'tcp',
                FromPort: '8080',
                ToPort: '8080'
            },
            {
                CidrIp: ref('AccessCidr'),
                IpProtocol: 'tcp',
                FromPort: '443',
                ToPort: '443'
            }
        ]
    }

    resource 'InstanceRole', Type: 'AWS::IAM::Role', Properties: {
        AssumeRolePolicyDocument: {
            Statement: [
                {
                    Effect: 'Allow',
                    Principal: {
                        Service: [ 'ec2.amazonaws.com' ]
                    },
                    Action: [ 'sts:AssumeRole']
                }
            ]
        },
        Path: '/'
    }

    resource 'RolePolicies', Type: 'AWS::IAM::Policy', Properties: {
        PolicyName: 'S3Download',
        PolicyDocument: {
            Statement: [
                {
                    Action: [ 's3:ListBucket', 's3:GetBucketLocation', 's3:GetObject', 's3:PutObject' ],
                    Effect: 'Allow',
                    Resource: [ join('', 'arn:aws:s3:::', ref('CfnBucket'), '/*') ]
                },
                {
                    Action: [
                        'ec2:AttachNetworkInterface',
                        'ec2:DescribeInstances',
                        'ec2:DescribeInstanceStatus',
                        'ec2:DescribeNetworkInterfaces',
                        'ec2:DetachNetworkInterface',
                        'ec2:DescribeNetworkInterfaceAttribute'
                    ],
                    Effect: 'Allow',
                    Resource: '*'
                }
            ]
        },
        Roles: [ ref('InstanceRole') ]
    }

    resource 'BucketProfile', Type: 'AWS::IAM::InstanceProfile', Properties: {
        Path: '/',
        Roles: [ ref('InstanceRole') ]
    }

    resource 'ElasticIp', Type: 'AWS::EC2::EIP', Properties: {
        Domain: 'vpc'
    }

    resource 'NetworkInterface', Type: 'AWS::EC2::NetworkInterface', Properties: {
        Description: 'Public Interface',
        GroupSet: [
            fn_if('AccessSecCond', ref('AccessSecurity'), ref('AccessSecurityGroup'))
        ],
        SubnetId: ref('AccessSubnet'),
        Tags: [
            {
                Key: 'Name',
                Value: 'PROD-JENKINS-ENI'
            }
        ]
    }

    resource 'AssociateIp', Type: 'AWS::EC2::EIPAssociation', Properties: {
        AllocationId: get_att('ElasticIp', 'AllocationId'),
        NetworkInterfaceId: ref('NetworkInterface')
    }

    resource 'JenkinsLaunchConfig', Type: 'AWS::AutoScaling::LaunchConfiguration', Properties: {
        AssociatePublicIpAddress: true,
        IamInstanceProfile: ref('BucketProfile'),
        ImageId: ref('ServerAmi'),
        InstanceType: ref('InstanceType'),
        KeyName: ref('KeyName'),
        SecurityGroups: [
            fn_if('AdminSecCond', ref('AdminSecurity'), ref('AdminSecurityGroup'))
        ],
        UserData: base64(interpolate(file('scripts/userdata.sh')))
    },
    Metadata: {
        'AWS::CloudFormation::Authentication': {
            S3AccessCreds: {
                type: 'S3',
                roleName: ref('InstanceRole')
            }
        },
        'AWS::CloudFormation::Init': {
            configSets: {
                InstallAndRun: [
                    'Install',
                    'Configure'
                ]
            },
            Install: {
                packages: {
                    yum: {}
                },
                files: {
                    '/etc/cfn/cfn-hup.conf': {
                        content: interpolate(file('config/cfn-hup.conf.tpl')),
                        mode: '0644',
                        owner: 'root',
                        group: 'root'
                    },
                    '/etc/cfn/cfn-auto-reloader.conf': {
                        content: interpolate(file('config/cfn-auto-reloader.conf.tpl')),
                        mode: '0644',
                        owner: 'root',
                        group: 'root'
                    }
                },
                services: {
                    'sysvinit': { enabled: true, ensurerunning: true },
                    'cfn-hup': { enabled: true, ensurerunning: true, files: [ '/etc/cfn/cfn-hup.conf', '/etc/cfn/hooks.d/cfn-auto-reloader.conf' ] },
                    'tomcat8': { enabled: true, ensurerunning: true, files: [ '/etc/tomcat8/tomcat8.conf' ] },
                    'newrelic-sysmond': { enabled: true, ensurerunning: true, files: [ '/etc/newrelic/nrsysmond.cfg' ] }
                }
            },
            Configure: {
                commands: {
                    '10_conf_newrelic': {
                        command: join('', 'nrsysmond-config --set license_key=', ref('NewRelicKey'))
                    },
                    '20_start_newrelic': {
                        command: '/etc/init.d/newrelic-sysmond start'
                    },
                    '30_nr_agent_config': {
                        command: 'cd /tmp ; unzip /tmp/newrelic-java.zip ; mv newrelic /usr/share/tomcat8'
                    },
                    '31_nr_agent_config': {
                        command: 'echo "JAVA_OPTS=\"-javaagent:/usr/share/tomcat8/newrelic/newrelic.jar\"" >> /etc/tomcat8/tomcat8.conf'
                    },
                    '90_download_tomcat': {
                        command: join('', 'aws s3 cp s3://', ref('CfnBucket'), '/', ref('Product'), '/jenkins-backup.tar.gz /tmp/jenkins-backup.tar.gz')
                    },
                    '91_restore_tomcat': {
                        command: 'tar -xf /tmp/jenkins-backup.tar.gz -C /usr/share/tomcat8'
                    },
                    '92_tomcat_access': {
                        command: 'chown -R tomcat:tomcat /usr/share/tomcat8/.jenkins'
                    },
                    '99_start_tomcat': {
                        command: 'service tomcat8 restart'
                    }
                }
            }
        }
    }

    resource 'JenkinsAutoScalingGroup', Type: 'AWS::AutoScaling::AutoScalingGroup', Properties: {
        AvailabilityZones: [ ref('AZ') ],
        Cooldown: '600',
        DesiredCapacity: '1',
        LaunchConfigurationName: ref('JenkinsLaunchConfig'),
        MaxSize: '1',
        MinSize: '1',
        TerminationPolicies: [
            'OldestInstance',
            'ClosestToNextInstanceHour'
        ],
        VPCZoneIdentifier: [
            ref('AdminSubnet')
        ],
        Tags: [
            {
                Key: 'Name',
                Value: 'Production Jenkins Instance',
                PropagateAtLaunch: true
            }
        ]
    }

    resource 'JenkinsStart', Type: 'AWS::AutoScaling::ScheduledAction', Properties: {
        AutoScalingGroupName: ref('JenkinsAutoScalingGroup'),
        DesiredCapacity: '1',
        MaxSize: '1',
        MinSize: '1',
        Recurrence: '45 09 * * *'
    }

    resource 'JenkinsEnd', Type: 'AWS::AutoScaling::ScheduledAction', Properties: {
        AutoScalingGroupName: ref('JenkinsAutoScalingGroup'),
        DesiredCapacity: '0',
        MaxSize: '1',
        MinSize: '0',
        Recurrence: '12 00 * * *'
    }

    resource 'DnsEntry', Type: 'AWS::Route53::RecordSet', Condition: 'Register53', Properties: {
        HostedZoneName: join('', ref('ZoneName'), '.'),
        Comment: 'Continuous Integration Service',
        Name: join('', 'jenkins', '.', ref('ZoneName'), '.'),
        Type: 'A',
        TTL: '600',
        ResourceRecords: [ ref('ElasticIp') ]
    }

end.exec!
