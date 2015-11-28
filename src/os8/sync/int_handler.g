package sync

func printField(k string, v uint) {
	fmt.PrintStr(k)
	fmt.PrintStr("=")
	fmt.PrintUint(v)
	fmt.Println()
}

func printFrame(frame *intr.Frame) {
	printField("intr", uint(frame.Intr))
	printField("r0", frame.R0)
	printField("r1", frame.R1)
	printField("r2", frame.R2)
	printField("r3", frame.R3)
	printField("r4", frame.R4)
	printField("pc", frame.PC)
	printField("sp", frame.SP)
	printField("ret", frame.RET)
	printField("arg", frame.Arg)
	printField("ring", uint(frame.Ring))
}

var (
	IntrHandlers    [intr.Nintr]func(f *intr.Frame)
	UserIntrHandler func(f *intr.Frame)
)

func ihandler(frame *intr.Frame) *intr.Frame {
	// route all timer interrupts to the scheduler
	// no matter user or kernel mode.
	i := frame.Intr
	if i == intr.Timer {
		return theScheduler.cswitch(frame)
	}

	// kernel mode halts and panics are expected, just do it.
	if frame.Ring == 0 {
		if i == intr.Halt {
			halt() // shutting down here
		} else if i == intr.Panic {
			panic()
		}
	}

	// hook other interrupts, might be hardware ones.
	f := IntrHandlers[i]
	if f != nil {
		f(frame)
		return frame
	}

	// handle user interrupts, should be generated by user code
	if frame.Ring > 0 {
		UserIntrHandler(frame) // handle user level exceptions
		return frame
	}

	fmt.PrintStr("unhandled kernel interrupt/exception:\n")
	printFrame(frame)
	panic()
}