# bottom.sh - bottom (btm) system monitor configuration
# This file is symlinked to shell.d/ and sourced by .bashrc

# bottom is available as 'btm' command

# Useful bottom aliases
alias btm='btm'                                   # Default invocation
alias top='btm'                                   # Replace top with bottom
alias htop='btm'                                  # Replace htop with bottom

# bottom with specific options
alias btmbasic='btm --basic'                      # Simplified interface
alias btmtree='btm --tree'                        # Show process tree
alias btmavg='btm --avg_cpu'                      # Show average CPU
alias btmgroup='btm --group'                      # Group processes by name

# bottom with custom update rates
alias btm500='btm -r 500ms'                       # Fast refresh (500ms)
alias btm2='btm -r 2s'                            # Slow refresh (2s)

# Monitor specific resource
alias btmcpu='btm --default_widget_type=cpu'      # Focus on CPU
alias btmmem='btm --default_widget_type=mem'      # Focus on memory
alias btmproc='btm --default_widget_type=proc'    # Focus on processes
