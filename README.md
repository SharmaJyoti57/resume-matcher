# Resume ↔ Job Description Matcher

A Flutter app (with a small Python backend) that answers one question: **should I apply to this job?** It compares your resume and profile against a job description and returns a verdict (Apply, Stretch or Skip), any hard blockers, matched, partial and missing requirements with the resume evidence behind each one, and specific feedback on closing the gaps. The analysis is powered by the OpenAI API.

I built this to solve a real problem in my own job search: quickly checking how well my resume fits a specific posting, and where the real gaps and blockers are, before I spend time applying.

https://github.com/user-attachments/assets/9724529b-54a2-46af-b084-a5f8acb00151


## Features

- **Verdict first:** a large Apply / Stretch / Skip badge is the headline, with the 0-100 match score shown smaller. The score is calibrated to be realistic, not inflated.
- **Blockers banner:** hard constraints such as visa sponsorship, work-location or country restrictions, and clearance appear in a warning above the score, each with a one-line reason (for example, "Open only to X; your profile says Y"), because a blocker matters more than the match percentage.
- **Met, partial and missing skills:** three groups instead of two. "Partial" captures the "close but not quite" cases, such as a related degree or adjacent experience.
- **Evidence view:** tap any requirement to see the quote from your resume behind the verdict, so a wrong judgment can be caught in seconds and the result can be trusted or challenged.
- **Structured profile:** facts you enter yourself rather than ones guessed from the resume: country, optional city, and a Yes / No / Not set sponsorship toggle. Eligibility is checked against these facts. If your country is missing or unrecognized, you get a "check" prompt rather than a made-up blocker.
- **Saved resume:** stored on the device, so you only paste the job description each time.
- **History:** every analysis is saved locally with company, date and verdict, so you can review your pipeline.
- **Robust UX:** loading, error and retry states, request timeouts, and tolerant parsing. New response fields are optional, so older responses never crash the app.

## How it works

Analysis runs in two steps so the model can't be swayed by your profile when reading the job description:

1. **JD-only extraction:** the model reads the job description once, without seeing your profile, and returns its requirements and typed constraints (visa, country, clearance, and so on). The result is cached per job description.
2. **Resume check:** your resume and profile are checked against the extracted requirements. Eligibility (country, sponsorship) is compared in code against a built-in table of about 60 countries and their aliases, not left to the model.

Guardrails applied in code after the model responds:

- **Quote must support the label:** a visa constraint needs a visa or sponsorship word in its own quote, and a country restriction needs a country named in the quote. Otherwise it is dropped, so invented blockers don't appear.
- **Section scoping:** the JD's headings are used to drop "requirements" that actually come from intro, company or perks text. Duties and "preferred" lines become nice-to-have. If scoping would leave fewer than 3 requirements, it is skipped.
- **Tip validation:** each improvement tip must attach to a real gap and share a keyword with it. No tips for degree or years-of-experience requirements, or for evidence that couldn't be verified.
- **Degree equivalence:** B.E., B.Tech and similar count as a bachelor's degree, and a master's implies one.

The backend returns structured JSON (`verdict`, `score`, `partial_skills`, `hard_constraints`, and a `score_breakdown` listing every requirement with its status and evidence quote), which the app parses directly into the UI.

## Tech stack

- **Flutter / Dart:** UI, local storage and app logic
- **Python backend:** JD extraction, scoring logic, eligibility checks and validation
- **OpenAI API (`gpt-4o-mini`):** requirement extraction and resume analysis
- **flutter_dotenv:** local configuration (API keys are never committed)
- **http:** networking

## Running it locally

<!-- Fill in the exact backend commands for your setup. -->

1. Clone the repo
2. Start the backend. Create a `.env` file with your key, then run the server:

   ```
   OPENAI_API_KEY=your-key-here
   ```

3. In the Flutter project, run `flutter pub get`
4. Point the app at your backend URL in its `.env` file
5. Run `flutter run`

## Testing

```
python test_logic.py
python eval.py regression_cases.json --repeats 1 --verbose
```

`test_logic.py` covers the deterministic logic: constraint validation, country matching, section scoping and tip validation. `eval.py` runs regression cases against the live model, covering no profile, US with and without sponsorship needs, and a non-US profile. The regression set is a small safety net, not a benchmark, so wider checks across many varied resume and JD pairs are still needed.

## What's next

- **Compare mode:** paste 2 to 5 job descriptions and rank them against your resume
- **Pipeline status:** applied, skipped or interviewing, tracked in history
- **Paste cleanup:** strip job-board boilerplate and add a copy-feedback button
- **Production hardening:** lock down CORS and use environment-specific API URLs
- **PDF upload** for resume and job description instead of pasting text
- **Persistent cache:** the JD cache is in memory today and resets when the server restarts

## Why I built this

I'm a Flutter developer with professional experience building and shipping cross-platform apps (published to both the App Store and Play Store), currently exploring how to integrate practical AI features into mobile applications. This project combines both: a real Flutter app with a genuinely useful AI layer, solving a problem I actually have.
