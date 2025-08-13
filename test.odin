#+private file
package xoshiro256pp

import "core:math/rand"
import "core:testing"

rng := xoshiro_random_generator()
@(test)
correctness :: proc(t: ^testing.T) {
	context.random_generator = rng

	rand.reset(12069)
	testing.expect_value(t, rand.uint64(rng), 6822165461875935344)
	testing.expect_value(t, rand.uint64(rng), 8025991002992936016)
	testing.expect_value(t, rand.uint64(rng), 9803362972432194534)

	rand.reset(123456789)
	testing.expect_value(t, rand.uint64(rng), 11051695339995113534)
	testing.expect_value(t, rand.uint64(rng), 4988023938500368323)
	testing.expect_value(t, rand.uint64(rng), 15893326098585791437)

	rand.reset(0xDEADBEEF)
	testing.expect_value(t, rand.uint64(rng), 3801289226785515695)
	testing.expect_value(t, rand.uint64(rng), 16228100807790805918)
	testing.expect_value(t, rand.uint64(rng), 14523653586541288138)

}
