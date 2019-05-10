# Terraform Route53 + ACM Certificate bug?

This repo demonstrates a bug in Terraform 0.11.13 where a Route53 entry is not
updated as expected when it's corresponding ACM Certificate is updated. The
`main.tf` is based on the [Terraform documentation for ACM Ceritificate
Validation](https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html).


When using AWS Route53 + an ACM Certificate as per the [ACM Certificate
Validation docs](https://www.terraform.io/docs/providers/aws/r/acm_certificate_validation.html),
the Route53 record is not updated to a new value if changes are made which
result in a new url being required after initial deployment. A new ACM
Certificate will be generated as expected however a new Route53 record will
not. This results in a couple things when deploying changes:
* ACM Certificate Validation will keep retrying until it eventually times out.
This is because a new ACM Certificate will be created but will stay in a
"pending" state as no corresponding Route53 entry will be created to validate
the certificate (via DNS validation).
* A new Route53 entry with update url is not created so now you have a cert for
the new url but no corresponding Route53 record.


## Steps to reproduce

Create a `terraforms.tfvars` file based on the `terraform.tfvars.example` file.

Run the Terraform script to deploy the Route53 entry and ACM Certificate with a
url based on your `terraform.tfvars` file. Outputs below are snippets of an
example run.

```(sh)
$ terraform init
  ...
  Terraform has been successfully initialized!
  ...

$ terraform plan -var-file=terraform.tfvars -out=tfplan -input=false
  ...
  Terraform will perform the following actions:
  + aws_acm_certificate.lb
      id:                          <computed>
      arn:                         <computed>
      domain_name:                 "dev.terraformers.odl.io"
      domain_validation_options.#: <computed>
      subject_alternative_names.#: <computed>
      tags.%:                      "2"
      tags.Name:                   "cert-dev"
      tags.Owner:                  "me@github.com"
      validation_emails.#:         <computed>
      validation_method:           "DNS"
  + aws_acm_certificate_validation.lb
      id:                          <computed>
      certificate_arn:             "${aws_acm_certificate.lb.arn}"
      validation_record_fqdns.#:   <computed>
  + aws_route53_record.lb
      id:                          <computed>
      allow_overwrite:             <computed>
      fqdn:                        <computed>
      name:                        "${aws_acm_certificate.lb.domain_validation_options.0.resource_record_name}"
      records.#:                   <computed>
      ttl:                         "60"
      type:                        "${aws_acm_certificate.lb.domain_validation_options.0.resource_record_type}"
      zone_id:                     "Z2O1O4B694O3BJ"

  Plan: 3 to add, 0 to change, 0 to destroy.
  ------------------------------------------------------------------------
  This plan was saved to: tfplan

$ terraform apply tfplan
  ...
  Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
 ```

Next modify the `env` variable in the Route53 entry to a different value and
then re-run `terraform plan`.

#### Expected:

```(sh)
$ terraform plan
...
Terraform will perform the following actions:

-/+ aws_acm_certificate.lb (new resource required)
      id:                                 "arn:aws:acm:us-west-2:0123456789:certificate/a8b6fld-e48e2-3d60-4d73-ad69aa13vj59" => <computed> (forces new resource)
      arn:                                "arn:aws:acm:us-west-2:0123456789:certificate/a8b6fld-e48e2-3d60-4d73-ad69aa13vj59" => <computed>
      domain_name:                        "dev.terraformers.odl.io" => "new-dev.terraformers.odl.io" (forces new resource)
      domain_validation_options.#:        "1" => <computed>
      subject_alternative_names.#:        "0" => <computed>
      tags.%:                             "2" => "2"
      tags.Name:                          "cert-dev" => "cert-new-dev"
      tags.Owner:                         "me@github.com" => "me@github.com"
      validation_emails.#:                "0" => <computed>
      validation_method:                  "DNS" => "DNS"

-/+ aws_acm_certificate_validation.lb (new resource required)
      id:                                 "2019-05-10 03:03:31 +0000 UTC" => <computed> (forces new resource)
      certificate_arn:                    "arn:aws:acm:us-west-2:0123456789:certificate/a8b6fld-e48e2-3d60-4d73-ad69aa13vj59" => "${aws_acm_certificate.lb.arn}" (forces new resource)
      validation_record_fqdns.#:          "1" => "1"
      validation_record_fqdns.1733237973: "_e2bs421lf4e708c3da07092bf312kl3ja9.dev.terraformers.odl.io" => "_e2bs421lf4e708c3da07092bf312kl3ja9.dev.terraformers.odl.io"

-/+ aws_route53_record.lb (new resource required)
      id:                        "Z2O1O4B694O3BJ__e2bs421lf4e708c3da07092bf312kl3ja9.dev.terraformers.odl.io._CNAME" => <computed> (forces new resource)
      allow_overwrite:           "" => <computed>
      fqdn:                      "_e2bs421lf4e708c3da07092bf312kl3ja9.dev.terraformers.odl.io" => <computed>
      name:                      "_e2bs421lf4e708c3da07092bf312kl3ja9.dev.terraformers.odl.io" => "_2b411592bf70bfc6016328d75444cef2.new-dev.terraformers.odl.io" (forces new resource)
      records.#:                 "1" => "1"
      records.2395981627:        "" => "_e2125a971689e6575266e435d9c65fe0.ltfvzjuylp.acm-validations.aws."
      records.450045610:         "_68e84a9d2a186a67153ee75ad6703a26.ltfvzjuylp.acm-validations.aws." => ""
      ttl:                       "60" => "60"
      type:                      "CNAME" => "CNAME"
      zone_id:                   "Z2O1O4B694O3BJ" => "Z2O1O4B694O3BJ"

Plan: 3 to add, 0 to change, 3 to destroy.

```

#### Actual:

```(sh)
...
Terraform will perform the following actions:

-/+ aws_acm_certificate.lb (new resource required)
      id:                                 "arn:aws:acm:us-west-2:0123456789:certificate/a8b6fld-e48e2-3d60-4d73-ad69aa13vj59" => <computed> (forces new resource)
      arn:                                "arn:aws:acm:us-west-2:0123456789:certificate/a8b6fld-e48e2-3d60-4d73-ad69aa13vj59" => <computed>
      domain_name:                        "dev.terraformers.odl.io" => "new-dev.terraformers.odl.io" (forces new resource)
      domain_validation_options.#:        "1" => <computed>
      subject_alternative_names.#:        "0" => <computed>
      tags.%:                             "2" => "2"
      tags.Name:                          "cert-dev" => "cert-new-dev"
      tags.Owner:                         "me@github.com" => "me@github.com"
      validation_emails.#:                "0" => <computed>
      validation_method:                  "DNS" => "DNS"

-/+ aws_acm_certificate_validation.lb (new resource required)
      id:                                 "2019-05-10 03:03:31 +0000 UTC" => <computed> (forces new resource)
      certificate_arn:                    "arn:aws:acm:us-west-2:0123456789:certificate/a8b6fld-e48e2-3d60-4d73-ad69aa13vj59" => "${aws_acm_certificate.lb.arn}" (forces new resource)
      validation_record_fqdns.#:          "1" => "1"
      validation_record_fqdns.1733237973: "_e2bs421lf4e708c3da07092bf312kl3ja9.dev.terraformers.odl.io" => "_e2bs421lf4e708c3da07092bf312kl3ja9.dev.terraformers.odl.io"

Plan: 2 to add, 0 to change, 2 to destroy.
```

The Route53 entry is not updated and then the ACM Certificate Validation fails
due to a timeout when terraform apply is applied. The reason for the failure is
because the ACM Certificate stays in a "pending" status as it does not get
validated correctly.

## Workaround

One workaround for this issue is to re-run `Terraform apply tfplan` after it
fails on the second run. Sometimes two re-runs are needed... This isn't very
elegant but you will see the Route53 entry will now be changed to the expected
value on subsequent run.

Obviously this won't help for people using automation to reapply their plans
but its a start at least.
