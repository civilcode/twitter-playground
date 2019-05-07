defmodule Twitter.Tweet do
  defstruct [id: nil, text: nil]

  @type t :: %__MODULE__{}
end
