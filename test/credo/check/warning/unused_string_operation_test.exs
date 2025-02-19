defmodule Credo.Check.Warning.UnusedStringOperationTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.UnusedStringOperation

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        String.split(parameter1) + parameter2
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report when result is piped" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        String.split(parameter1)
        |>  some_where

        parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when end of pipe AND return value" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      parameter1 + parameter2
      |> String.split(parameter1)
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside of pipe" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      parameter1 + parameter2
      |> String.split(parameter1)
      |> some_func_who_knows_what_it_does

      :ok
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside an assignment" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      offset = String.length(line) - String.length(String.trim(line))

      parameter1 + parameter2 + offset
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside a condition" do
    """
    defmodule CredoSampleModule do
    def some_function(parameter1, parameter2) do
      if String.length(x1) > String.length(String.trim(x2)) do
        cond do
          String.trim(x3) == "" -> IO.puts("1")
          String.length(x) == 15 -> IO.puts("2")
          String.replace(x, "a", "b") == "b" -> IO.puts("2")
        end
      else
        case String.length(x3) do
          0 -> true
          1 -> false
          _ -> something
        end
      end
      unless String.trim(x4) == "" do
        IO.puts "empty"
      end

      parameter1 + parameter2 + offset
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside a quote" do
    """
    defmodule CredoSampleModule do
    defp category_body(nil) do
      quote do
        __MODULE__
        |> Module.split
        |> Enum.at(2)
        |> String.downcase
        |> String.to_atom
      end
    end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside a catch" do
    """
    defmodule CredoSampleModule do
      defp category_body(nil) do
        throw [1, 2, 3, 4]
      catch
        values ->
          String.to_atom(values)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when inside of assignment" do
    """
    defmodule CredoSampleModule do
    defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
      pos =
        pos_string(issue.line_no, issue.column)

      [
        Output.issue_color(issue), "┃ ",
        Output.check_tag(check), " ", priority |> Output.priority_arrow,
        :normal, :white, " ", message,
      ]
      |> IO.ANSI.format
      |> IO.puts

      if issue.column do
        offset = String.length(line) - String.length(String.trim(line))
        [
            String.duplicate(" ", x), :faint, String.duplicate("^", w),
        ]
        |> IO.puts
      end

      [Output.issue_color(issue), :faint, "┃ "]
      |> IO.ANSI.format
      |> IO.puts
    end

    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when call is buried in else block but is the last call" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          [:this_actually_might_return, String.duplicate("^", w), :ok] # THIS is not the last_call!
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when call is buried in else block and is not the last call, but the result is assigned to a variable" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        result =
          if issue.column do
            IO.puts "."
          else
            [:this_goes_nowhere, String.duplicate("^", w)]
          end

        IO.puts "8"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when buried in :if, :when and :fn 2" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          case check do
            true -> false
            _ ->
              Enum.reduce(arr, fn(w) ->
                [:this_might_return, String.duplicate("^", w)]
              end)
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when :for and :case" do
    """
    defmodule CredoSampleModule do
      defp convert_parsers(parsers) do
        for parser <- parsers do
          case Atom.to_string(parser) do
            "Elixir." <> _ -> parser
            reference      -> String.upcase(reference)
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when part of a function call" do
    """
    defmodule CredoSampleModule do
      defp convert_parsers(parsers) do
        for parser <- parsers do
          case Atom.to_string(parser) do
            "Elixir." <> _ -> parser
            reference      -> Module.concat(Plug.Parsers, String.upcase(reference))
          end
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when :for and :case 2" do
    """
    defmodule CredoSampleModule do
      defp convert_parsers(parsers) do
        for segment <- String.split(bin, "/"), segment != "", do: segment
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in :after block" do
    """
      defp my_function(fun, opts) do
        try do
          :fprof.analyse(
            dest: analyse_dest,
            totals: true,
            details: Keyword.get(opts, :details, false),
            callers: Keyword.get(opts, :callers, false),
            sort: sorting
          )
        else
          :ok ->
            {_in, analysis_output} = StringIO.contents(analyse_dest)
            String.to_charlist(analysis_output)
        after
          StringIO.close(analyse_dest)
        end
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in function call" do
    """
      def my_function(url) when is_binary(url) do
        if info.userinfo do
          destructure [username, password], String.split(info.userinfo, ":")
        end

        Enum.reject(opts, fn {_k, v} -> is_nil(v) end)
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in function call 2" do
    """
      defp print_process(pid_atom, count, own) do
        IO.puts([?", String.duplicate("-", 100)])
        IO.write format_item(Path.join(path, item), String.pad_trailing(item, width))
        print_row(["s", "B", "s", ".3f", "s"], [count, "", own, ""])
      end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in list that is returned" do
    """
    defp indent_line(str, indentation, with \\\\ " ") do
      [String.duplicate(with, indentation), str]
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in rescue" do
    """
    defmodule Buggy do
      @moduledoc false
      def parse(str) do
        String.to_integer(str)
      rescue
        ArgumentError -> String.to_float(str)
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in rescue /2" do
    """
    defmodule Buggy do
      @moduledoc false
      def parse(str) do
        :bar

        try do
          String.to_integer(str)
        rescue
          ArgumentError -> String.to_float(str)
        else
          y when y < 1 and y > -1 ->
            :small
          _ ->
            :large
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report a violation when in rescue /3" do
    """
    defmodule Buggy do
      @moduledoc false
      def parse(str) do
        :bar

        try do
          :something
        rescue
          ArgumentError -> :error
        else
          y when y < 1 and y > -1 ->
            String.to_float(str)
          _ ->
            :large
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  ##############################################################################
  ##############################################################################

  test "it should report a violation" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        x = parameter1 + parameter2

        String.split(parameter1)

        parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when end of pipe" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        parameter1 + parameter2
        |> String.split(parameter1)

        parameter1
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when buried in :if" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          [
            :this_goes_nowhere,
            String.duplicate("^", w) # THIS is not the last_call!
          ]
          IO.puts "."
        else
          IO.puts "x"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when buried in :else" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          String.trim(filename)
          IO.puts "x"
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when buried in :if, :when and :fn" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          case check do
            true -> false
            _ ->
              [:this_goes_nowhere, String.duplicate("^", w)]
          end
        end

        IO.puts "x"
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when call is buried in else block but is the last call" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          [:this_goes_nowhere, String.duplicate("^", w)] # THIS is not the last_call!
        end

        IO.puts
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation when call is buried in else block but is the last call 2" do
    """
    defmodule CredoSampleModule do
      defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file) do
        if issue.column do
          IO.puts "."
        else
          [:this_goes_nowhere, String.duplicate("^", w)] # THIS is not the last_call!

          IO.puts " "
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "String.duplicate" == issue.trigger
    end)
  end

  test "it should report several violations" do
    """
    defmodule CredoSampleModule do
      def some_function(parameter1, parameter2) do
        String.split(parameter1)
        parameter1
      end
      def some_function2(parameter1, parameter2) do
       String.trim(parameter1)
       parameter1
       end
       def some_function3(parameter1, parameter2) do
         String.trim(parameter1)
         parameter1
       end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues(fn issues ->
      assert 3 == Enum.count(issues)
    end)
  end

  test "it should report a violation when used incorrectly, even inside a :for" do
    """
    defmodule CredoSampleModule do
      defp something(bin) do
        for segment <- String.split(bin, "/"), segment != "" do
          String.upcase(segment)

          segment
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "String.upcase" == issue.trigger
    end)
  end

  test "it should report a violation when not last call in rescue" do
    """
    defmodule Buggy do
      @moduledoc false
      def parse(str) do
        String.to_integer(str)
      rescue
        ArgumentError ->
          String.to_float(str)

          :error
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "String.to_float" == issue.trigger
    end)
  end

  test "it should report a violation when in rescue /2" do
    """
    defmodule Buggy do
      @moduledoc false
      def parse(str) do
        :bar

        try do
          :something
        rescue
          ArgumentError -> String.to_float(str)
        else
          y when y < 1 and y > -1 ->
            :small
          _ ->
            :large
        end

        :actual_return
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "String.to_float" == issue.trigger
    end)
  end

  test "it should report a violation when in rescue /3" do
    """
    defmodule Buggy do
      @moduledoc false
      def parse(str) do
        :bar

        try do
          :something
        rescue
          ArgumentError -> :error
        else
          y when y < 1 and y > -1 ->
            String.to_float(str)

            :small
          _ ->
            :large
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "String.to_float" == issue.trigger
    end)
  end

  test "it should report a violation when in rescue /4" do
    """
    defmodule Buggy do
      @moduledoc false
      def parse(str) do
        :bar

        try do
          :something
        rescue
          ArgumentError -> :error
        after
          String.to_float(str)
        end
      end
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert "String.to_float" == issue.trigger
    end)
  end
end
