package xoshiro256pp

import "core:math/rand"
import "core:testing"

when ODIN_TEST {
	@(test)
	test_determinism :: proc(t: ^testing.T) {
		context.random_generator = xoshiro_random_generator()
		rand.reset(13)
		first_value := rand.int127()
		rand.reset(13)
		second_value := rand.int127()

		testing.expect(
			t,
			first_value == second_value,
			"xoshiro random number generator is non-deterministic.",
		)
	}

	@(test)
	test_determinism_user_set :: proc(t: ^testing.T) {

		rng_state_1 := create_state(13)
		rng_state_2 := create_state(13)

		rng_1 := xoshiro_random_generator(&rng_state_1)
		rng_2 := xoshiro_random_generator(&rng_state_2)

		first_value, second_value: i128
		{
			context.random_generator = rng_1
			first_value = rand.int127()
		}
		{
			context.random_generator = rng_2
			second_value = rand.int127()
		}

		testing.expect(
			t,
			first_value == second_value,
			"User-set xoshiro random number generator is non-deterministic.",
		)
	}
}
