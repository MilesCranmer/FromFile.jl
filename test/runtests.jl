using FromFile
using Test

module wrapper1
	using FromFile
	visible = [:A]
	invisible = [:foo, :bar, :baz, :quux, :B, :C]
	
    @from "basic.jl" import A
end

module wrapper2
	using FromFile
	visible = [:foo]
	invisible = [:bar, :baz, :quux, :A, :B, :C]
	
	@from "basic.jl" import A: foo
end

module wrapper3
	using FromFile
	visible = [:foo, :B]
	invisible = [:bar, :baz, :quux, :A, :C]
	
	@from "basic.jl" import A: foo, B
end

module wrapper4
	using FromFile
	visible = [:foo]
	invisible = [:bar, :baz, :quux, :A, :B, :C]
	
    @from "basic.jl" import A.foo
end

module wrapper5
	using FromFile
	visible = [:foo, :baz, :B]
	invisible = [:bar, :quux, :A, :C]
	
    @from "basic.jl" import A.foo, A.B.baz, A.B
end

module wrapper6
	using FromFile
	visible = [:foo, :A, :B]
	invisible = [:bar, :baz, :quux, :C]
	
	@from "basic.jl" using A
end

module wrapper7
	using FromFile
	visible = [:foo]
	invisible = [:bar, :baz, :quux, :A, :B, :C]
	
	@from "basic.jl" using A: foo
end

module wrapper8
	using FromFile
	visible = [:foo, :B]
	invisible = [:bar, :baz, :quux, :A, :C]
	
	@from "basic.jl" using A: foo, B
end

module wrapper9
	using FromFile
	visible = [:baz]
	invisible = [:foo, :bar, :quux, :A, :B, :C]
	
	@from "basic.jl" using A.B: baz
end

module wrapper10
	using FromFile
	visible = [:A, :C]
	invisible = [:foo, :bar, :baz, :quux, :B]
	
    @from "basic.jl" import A, C
end

module wrapper11
	using FromFile
	visible = [:foo, :quux, :A, :B, :C]
	invisible = [:bar, :baz]
	
    @from "basic.jl" using A, C
end

module wrapper_chain
	using FromFile
	@from "chain.jl" import a, b, b2, c, c2, d, e
end

@testset "Tests from REPL" begin
	# Make sure that we're not affecting this namespace
	@test !isdefined(@__MODULE__, :A)
	@test !isdefined(@__MODULE__, :foo)
	@test !isdefined(@__MODULE__, :bar)
	@test !isdefined(@__MODULE__, :B)
	@test !isdefined(@__MODULE__, :baz)
	@test !isdefined(@__MODULE__, :C)
	@test !isdefined(@__MODULE__, :quux)
	
	# Check the right things are or aren't there.
	for wrapper in (wrapper1, wrapper2, wrapper3, wrapper4, wrapper5, wrapper6, wrapper7, wrapper8, wrapper9, wrapper10, wrapper11)
		for visible in wrapper.visible
			@eval @test isdefined($wrapper, $(QuoteNode(visible)))
		end
		for invisible in wrapper.invisible
			@eval @test !isdefined($wrapper, $(QuoteNode(invisible)))
		end
	end
	
	# Make sure that the import modules are where we expect them to be
	project_path = dirname(dirname(pathof(FromFile)))
	file_symbol = Symbol(abspath(joinpath(project_path, "test", "basic.jl")))
	@test fullname(wrapper1.A) == (:Main, file_symbol, :A)

	# Check we get the same thing every time
	visible_dict = Dict{Symbol, Array}()
	for wrapper in (wrapper1, wrapper2, wrapper3, wrapper4, wrapper5, wrapper6, wrapper7, wrapper8, wrapper9, wrapper10, wrapper11)
		for visible_symbol in wrapper.visible
			if !haskey(visible_dict, visible_symbol)
				visible_dict[visible_symbol] = []
			end
			push!(visible_dict[visible_symbol], getproperty(wrapper, visible_symbol))
		end
	end
	for visible_array in values(visible_dict)
		for visible_obj in visible_array[2:end]
			@test visible_obj === visible_array[1]
		end
	end

	@test wrapper_chain.a == 1
	@test wrapper_chain.b == 2
	@test wrapper_chain.b2 == 2.5
	@test wrapper_chain.c == 3
	@test wrapper_chain.c2 == 3.5
	@test wrapper_chain.d == 4
	@test wrapper_chain.e == 5
end