# AI Assistance Disclosure

Tiny8 was developed with substantial assistance from OpenAI Codex/ChatGPT. The
assistant drafted significant portions of the Verilog RTL, self-checking
testbenches, program images, build automation, and project documentation. It
also suggested architecture and debugging approaches, interpreted simulation,
lint, waveform, and synthesis output, and helped organize local Git commits.
Development proceeded incrementally, one module at a time; this describes the
workflow and does not imply that the final source was independently handwritten
by the human author.

The human project author chose or approved the project scope and design
decisions, directed the order of work, ran some local checks, inspected
waveforms, and asked questions to understand the resulting hardware behavior.
The human author is responsible for the final submission, for complying with
any applicable AI-use policy, and for being able to explain, reproduce, and
modify the submitted design. Any part not personally reviewed or understood
should not be represented as such.

AI responses were not treated as verification. Reported results come from
reproducible Icarus Verilog simulations and self-checking testbenches, Verilator
lint, Yosys synthesis checks, and manual GTKWave inspection. These checks show
that the checked-in design passed the documented cases in the stated
environment; they are not formal proof, hardware validation, an ASIC tapeout,
or professional semiconductor experience.
