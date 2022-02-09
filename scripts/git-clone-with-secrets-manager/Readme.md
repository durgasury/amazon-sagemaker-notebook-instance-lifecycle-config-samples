## Automatically cloning a git repository to SageMaker notebook

This lifecycle configuration (LCC) automatically clones a GitHub repository to the notebook's home folder. It assumes the credentials are stored in Secrets Manager. If it is a publicly available git repository, you can skip the set up and simply use the `git clone` part of the LCC script. 

`sample_template.yaml` is a sample CloudFormation template that will create a SageMaker role, the notebook LCC and notebook instance. 