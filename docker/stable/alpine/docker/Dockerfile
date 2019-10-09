
#
# PSRule
#

ARG fromTag=alpine-3.8
ARG imageRepo=mcr.microsoft.com/powershell
ARG VCS_REF="none"
ARG MODULE_VERSION=0.9.0

# Use PowerShell image
FROM ${imageRepo}:${fromTag}
SHELL ["pwsh", "-NoLogo", "-NoProfile", "-Command"]
RUN Install-Module -Name PSRule -RequiredVersion ${MODULE_VERSION} -Force;

CMD ["pwsh"]

# Add standard labels -- http://label-schema.org/
LABEL maintainer="Bernie White" \
    readme.md="https://github.com/BernieWhite/PSRule/blob/master/README.md" \
    description="Validate objects using PowerShell rules." \
    org.label-schema.name="PSRule" \
    org.label-schema.url="https://berniewhite.github.io/PSRule/" \
    org.label-schema.vcs-url="https://github.com/BernieWhite/PSRule.Rules/" \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vendor="Bernie White" \
    org.label-schema.version=${MODULE_VERSION} \
    org.label-schema.schema-version="1.0"
