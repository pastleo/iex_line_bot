defmodule IexLineBot do
  alias IexLineBot.Memory
  @moduledoc """
  IexLineBot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def string(text, memory_key) do
    try do
      IO.inspect(%{text: text, memory_key: memory_key})
      {result, new_bindings} =
        Code.string_to_quoted(text)
        |> safe_eval(Memory.get(memory_key))
      IO.inspect(%{result: result, new_bindings: new_bindings})

      Memory.set(memory_key, new_bindings)
      to_string(result)
    rescue
      e -> error_string(e)
    end
    |> IO.inspect()
  end

  defp error_string(%{description: description}) when description != "" do
    description
  end
  defp error_string(%{message: message}) when message != "" do
    message
  end
  defp error_string(%Protocol.UndefinedError{protocol: String.Chars}) do
    "[object Object]" # a joke for javascript
  end
  defp error_string(e) do
    IO.inspect({"unknown error", e})
    "...!"
  end

  def safe_eval({:ok, quoted}, bindings) do
    quoted
    |> sanitize()
    |> Code.eval_quoted(bindings)
  end
  def safe_eval(_, bindings) do
    {"...?", bindings}
  end

  def sanitize(quoted) do
    Macro.prewalk(quoted, &validate_expr/1)
  end

  defp validate_expr({:".", _, [module_expr, method]} = expr) do
    validate_method({module(module_expr), method})
    expr
  end
  defp validate_expr({method, _, _} = expr) when is_atom(method) do
    if kernel_method?(method) do
      validate_method({[:Kernel], method})
    end
    expr
  end
  defp validate_expr(expr), do: expr

  defp module({:__aliases__, _, module_name}), do: module_name

  @allowed_methods [
    {[:Kernel], :"!"},
    {[:Kernel], :"!="},
    {[:Kernel], :"!=="},
    {[:Kernel], :"&&"},
    {[:Kernel], :"*"},
    {[:Kernel], :"++"},
    {[:Kernel], :"+"},
    {[:Kernel], :"--"},
    {[:Kernel], :"-"},
    {[:Kernel], :".."},
    {[:Kernel], :"/"},
    {[:Kernel], :"<"},
    {[:Kernel], :"<="},
    {[:Kernel], :"<>"},
    {[:Kernel], :"=="},
    {[:Kernel], :"==="},
    {[:Kernel], :"=~"},
    {[:Kernel], :">"},
    {[:Kernel], :">="},
    {[:Kernel], :"|>"},
    {[:Kernel], :"||"},
    {[:Kernel], :"if"},

    {[:Enum], :sum},
  ]

  defp validate_method(method) do
    Enum.member?(@allowed_methods, method)
    |> raise_not_allowed_method(method)
  end

  defp raise_not_allowed_method(false, {module_name, method_name}) do
    module_name
    |> Kernel.++([to_string(method_name)])
    |> Enum.join(".")
    |> (&raise("not allowed to use #{&1}")).()
  end
  defp raise_not_allowed_method(true, _), do: nil

  @kernel_methods Enum.map(
    Kernel.__info__(:functions) ++ Kernel.__info__(:macros),
    &elem(&1, 0)
  )
  def kernel_method?(method) do
    Enum.member?(@kernel_methods, method)
  end
end
