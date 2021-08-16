# Rules Terraform
Terraform rules for Bazel

# Usage

In your `WORKSPACE`

```
http_archive(
    name = "io_bazel_rules_terraform",
    sha256 = "93f9bca5581d713649ddc44dabd1c953d6f129472abbcdc39136035aa39c1417",
    strip_prefix = "rules_terraform-7ffce42f76329713bec6f0fe961cd26f277a45bc",
    urls = ["https://github.com/uhthomas/rules_terraform/archive/7ffce42f76329713bec6f0fe961cd26f277a45bc.tar.gz"],
)

load("@io_bazel_rules_terraform//terraform:terraform.bzl", "terraform_register_toolchains")

terraform_register_toolchains(
    sha256s = {
        "darwin_amd64": "126e1c9e058f12c247a194db5a9567e59ec755cbc0211cd5d58c8b7d37412b2c",
        "linux_amd64": "63a5a45edde435fa3f278c86ce96346ee7f6b204ea949734f26f963b7dbc1074",
    },
    version = "0.14.6",
)
```

Import the rules you want to use in your build file:

```
load("@io_bazel_rules_terraform//terraform:terraform.bzl", "terraform_plan")

terraform_plan(
    name = "plan",
    srcs = glob(["**/*.tf"])
)
```


