resource "aws_emr_cluster" "cluster" {
  name          = var.emr_cluster_name
  release_label = var.ReleaseLabel
  applications  = var.applications
  termination_protection            = "false"
  log_uri                           = "s3://${var.LogBucket}/emr/${var.emr_cluster_name}"

  ec2_attributes {
    subnet_id                         = var.subnet_id
    key_name                          = var.key_name
    emr_managed_master_security_group = var.EmrMasterSecurityGroup
    emr_managed_slave_security_group  = var.EmrSlaveSecurityGroup
    additional_slave_security_groups  = var.slave_security_group
    additional_master_security_groups = var.master_security_group
    service_access_security_group     = var.EmrServiceSecurityGroup
    instance_profile                  = var.Instance_profile
  }

  master_instance_group {
    instance_type  = var.EmrMasterInstanceType
    instance_count = var.InstanceCount
    name           = var.masterinstancegroupname

    ebs_config {
      size                 = var.master_ebs_size
      type                 = var.master_instance_ebs_volume_type
      volumes_per_instance = var.master_volume_per_instance
    }

  }

  core_instance_group {
    instance_type  = var.EmrCoreInstanceType
    instance_count = var.EmrCoreNodes
    name           = "Core"

    ebs_config {
      size                 = "32"
      type                 = "gp2"
      volumes_per_instance = 1
    }

    autoscaling_policy = file("/emr/autoscaling_policy.json")
  }
  ebs_root_volume_size = 100
  tags = merge(var.tagsmap, { Name = var.emr_cluster_name }, )
  service_role         = var.service_role
  visible_to_all_users = true
}
/*
resource "aws_emr_security_configuration" "testing" {
  name = "SecConfig-${var.emr_cluster_name}"
  configuration = file("emr_security_configuration.json")
  }
}
*/
resource "aws_emr_managed_scaling_policy" "autoscaling_policy" {
  cluster_id = aws_emr_cluster.cluster.id
  compute_limits {
    unit_type                       = "Instances"
    minimum_capacity_units          = var.minimum_capacity_units
    maximum_capacity_units          = var.maximum_capacity_units
    maximum_ondemand_capacity_units = var.maximum_ondemand_capacity_units
    maximum_core_capacity_units     = var.maximum_core_capacity_units 
  }


  master_instance_fleet {
    name                      = var.master_instance_fleet_name
    target_on_demand_capacity = var.master_instance_on_demand_count
    target_spot_capacity      = var.master_instance_spot_count
    instance_type_configs {
      bid_price                                  = var.master_bid_price
      bid_price_as_percentage_of_on_demand_price = var.master_bid_price_as_percentage_of_on_demand_price
      instance_type                              = var.master_instance_type
      weighted_capacity                          = var.master_weighted_capacity
      ebs_config {
        size                 = var.master_ebs_size
        type                 = var.master_ebs_type
        volumes_per_instance = var.master_ebs_volumes_count
      }
    }
    dynamic "launch_specifications" {
      for_each = var.master_instance_spot_count > 0 ? [1] : []
      content {
        spot_specification {
          allocation_strategy      = "capacity-optimized"
          block_duration_minutes   = var.master_block_duration_minutes
          timeout_action           = var.master_timeout_action
          timeout_duration_minutes = var.master_timeout_duration_minutes
        }
      }
    }
  }

  core_instance_fleet {
    name                      = var.core_instance_fleet_name
    target_on_demand_capacity = var.core_instance_on_demand_count
    target_spot_capacity      = var.core_instance_spot_count
    instance_type_configs {
      bid_price                                  = var.core_bid_price
      bid_price_as_percentage_of_on_demand_price = var.core_bid_price_as_percentage_of_on_demand_price
      instance_type                              = var.core_instance_type
      weighted_capacity                          = var.core_weighted_capacity
      ebs_config {
        size                 = var.core_ebs_size
        type                 = var.core_ebs_type
        volumes_per_instance = var.core_ebs_volumes_count
      }
    }
    dynamic "launch_specifications" {
      for_each = var.core_instance_spot_count > 0 ? [1] : []
      content {
        spot_specification {
          allocation_strategy      = "capacity-optimized"
          block_duration_minutes   = var.core_block_duration_minutes
          timeout_action           = var.core_timeout_action
          timeout_duration_minutes = var.core_timeout_duration_minutes
        }
      }
    }
  }


  task_instance_fleet  {
    name                      = var.task_instance_fleet_name
    target_on_demand_capacity = var.task_target_on_demand_capacity
    target_spot_capacity      = var.task_target_spot_capacity
    instance_type_configs {
      bid_price                                  = var.task_bid_price
      bid_price_as_percentage_of_on_demand_price = var.task_bid_price_as_percentage_of_on_demand_price
      instance_type                              = var.task_instance_type
      weighted_capacity                          = var.task_weighted_capacity
      ebs_config {
        size                 = var.task_ebs_size
        type                 = var.task_ebs_type
        volumes_per_instance = var.task_ebs_volumes_count
      }
    }
    dynamic "launch_specifications" {
      for_each = var.task_instance_spot_count > 0 ? [1] : []
      content {
        spot_specification {
          allocation_strategy      = "capacity-optimized"
          block_duration_minutes   = var.task_block_duration_minutes
          timeout_action           = var.task_timeout_action
          timeout_duration_minutes = var.task_timeout_duration_minutes
        }
      }
    }
  }
}
