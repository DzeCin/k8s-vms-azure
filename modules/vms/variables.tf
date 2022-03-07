variable "vms" {
  type = list(object({

        nic = object({
          name = string
          ipconfname = string
        })

        pip = object({
          allocation_method = string
        })

        vm = object({
          name = string
          publisher = string
          offer     = string
          sku       = string
          version   = string

        })

    }))
}