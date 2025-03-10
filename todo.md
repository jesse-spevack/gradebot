# TODO

- [ ] Formatting of rubric and assignment prompt
    - [ ] In `ProcessGradingTask` we need to:
        - [ ] Send the rubric to claude and save the result as "formatted_rubric"
        ```
        prompt = <<~PROMPT
            Convert the following text into well-formatted HTML. 
            If it appears to be a rubric or table, format it as an HTML table.
            If it contains lists, format them as unordered or ordered lists as appropriate.
            Use appropriate heading tags for sections.
            Return ONLY the HTML with no explanation or markdown.
            
            Text to convert:
            #{text}
        PROMPT
        ```
        - [ ] Send the assignment to claude and save the result as "formatted_assignment"
        ```
        Convert the following assignment text into well-formatted HTML. Use paragraph tags for main text, unordered list tags for bullet points, and emphasize key instructions or requirements with strong tags. Preserve the original meaning and structure while making it more readable. Return ONLY the HTML with no explanation or markdown.

        Assignment text:
        {{assignment_text}} 
        ```
        - [ ] Use tailwind prose to display sanitized html of the formatted rubric and formatted assignment
            - https://github.com/tailwindlabs/tailwindcss-typography
- [ ] Show document name instead of document id 
- [ ] Add a summary of all student submissions to the grading task page
- [ ] Add validation llm task to check assignment and rubric
- [ ] Add validation llm task to check each student submission
- [ ] Review feature flag views
- [ ] Review llm pricing views


# DONE
- [x] Add admin page with toolbar on the left for all the things I need -> flags, cost reports etc 
- [x] Review how to track actual costs of requests 
- [x] BUG: status bubbles on grading task are not updating without page refresh
- [x] BUG: status bubbles on grading task not changing from pending to processing 
- [x] Styling of submission list and grade task need to be improved 
- [x] Formating of the feedback on the student submission page
- [x] Update the status timeline on the student submission page
- [x] Review cost reports
    - [x] date filter not working
    - [x] cost per day
- [x] Refactor process student submission command 