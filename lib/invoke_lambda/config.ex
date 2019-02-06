defmodule InvokeLambda.Config do
  def aws_access_key do
    System.get_env "aws_access_key_id"
  end
  
  def aws_secret_key do
    System.get_env "aws_secret_access_key"
  end
end
