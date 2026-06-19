function _wt_launch --argument-names agent prompt clone_dir
    # Launch one coding agent in "plan/review" mode. Agents are mutually exclusive.
    switch $agent
        case oc
            opencode --agent plan --prompt "$prompt" "$clone_dir"
        case cc
            claude --permission-mode plan --model opusplan --effort max "$prompt"
        case cx
            # Codex: read-only sandbox ~ plan mode; interactive with initial prompt.
            codex --sandbox read-only "$prompt"
        case pi
            # pi: interactive session seeded with the prompt.
            pi "$prompt"
        case '*'
            echo "Setup complete. No agent flag given (--oc/--cc/--cx/--pi)."
            return 0
    end
end
