` concurrent task queue `

std := load('../vendor/std')

log := std.log
each := std.each
range := std.range

new := maxConcurrency => (
	s := {
		idx: 0 ` next task `
		tasks: []
		running: 0
	}
	doNext := cb => (
		t := s.tasks.(s.idx)
		s.idx := s.idx + 1

		t :: {
			() -> cb()
			_ -> t(cb)
		}
	)
	runFromQueue := () => s.running :: {
		maxConcurrency -> ()
		_ -> (
			s.running := s.running + 1
			run := () => s.tasks.(s.idx) :: {
				() -> (
					s.running := s.running - 1
					s.running :: {
						0 -> (
							` reset queue state, in case of reuse `
							s.idx := 0
							s.tasks := []
						)
					}
				)
				_ -> doNext(run)
			}
			run()
		)
	}
	add := t => (
		s.tasks.len(s.tasks) := t
		runFromQueue()
	)

	{
		add: add
	}
)
