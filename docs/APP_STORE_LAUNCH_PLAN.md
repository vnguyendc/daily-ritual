# Daily Ritual -- App Store Launch Plan & Marketing Strategy

> Comprehensive playbook for launching Daily Ritual on the App Store and reaching first 1,000 users.

**Last updated:** February 2026

---

## 1. App Store Listing

### 1.1 App Name Options

| Option | Characters | Rationale |
|--------|-----------|-----------|
| **Daily Ritual** | 12 | Clean, memorable, matches domain and brand. Implies habit and consistency -- core value prop. |
| Daily Ritual: Athlete Journal | 28 | Adds keyword context for search. Fits 30-char limit. Immediately signals target audience. |
| Daily Ritual - Train Your Mind | 30 | Hooks the athlete mindset angle. Uses the website tagline. Exactly at the limit. |

**Recommendation:** Use **"Daily Ritual"** as the app name and put the keyword-rich qualifier in the subtitle. Shorter names are more memorable and look cleaner on the home screen.

### 1.2 Subtitle (max 30 characters)

```
Mental Training for Athletes
```

Alternative options:
- `Athlete Performance Journal` (27 chars)
- `Journal for Peak Performance` (29 chars)
- `Train Your Mind Daily` (21 chars)

### 1.3 Keywords (100 character limit)

```
journal,athlete,mental,training,reflection,streak,workout,gratitude,morning,routine,mindset,coaching
```

**Character count:** 99

Keyword strategy rationale:
- **High intent:** `journal`, `athlete`, `mental training`, `workout`
- **Behavioral:** `reflection`, `gratitude`, `morning routine`, `streak`
- **Differentiators:** `coaching`, `mindset`
- **Omitted (already in name/subtitle):** "daily", "ritual", "performance" -- Apple indexes these automatically from name and subtitle

### 1.4 Full App Store Description

```
Your physical training is structured, tracked, and optimized. Your mental training should be too.

Daily Ritual is the first journaling app built specifically for athletes. No blank pages. No generic prompts. Just a structured daily practice designed around how you actually train, recover, and compete.

THE DAILY PRACTICE

Morning Ritual (5 min)
Set three goals for the day. Practice gratitude. Receive a personalized affirmation based on your sport and recent patterns. Start every training day with clarity and intention.

Post-Workout Reflection
Capture what clicked and what didn't while the session is fresh. Rate your energy, focus, and overall feeling. Connect your mental state to your physical output.

Evening Reflection
Close the day honestly. What went well? What needs work? Track your mood and build the dataset that reveals your patterns over time.

WHY ATHLETES LOVE DAILY RITUAL

- Structured prompts designed for athletic performance, not generic wellness
- Streak tracking that builds consistency like training blocks build fitness
- AI insights that connect your mental state to training outcomes
- Celebration animations when you hit milestones -- because mental reps count too
- Training plan integration so your journal knows what you trained today

BUILT FOR YOUR SPORT

Whether you run, swim, cycle, lift, or compete in any individual sport, Daily Ritual adapts to your training rhythm. Morning person who trains at 5 AM? Night owl who reflects after evening practice? The app works around your schedule, not the other way around.

AI THAT UNDERSTANDS ATHLETES

Daily Ritual's AI doesn't give generic advice. It learns from YOUR patterns:
- "Your 5/5 training days happen 80% more when you complete your full morning ritual"
- "After tough sessions, your mood recovers faster when you focus on effort over outcome"
- "Your best competition weeks follow prep periods with anxiety at 2-3/5"

PREMIUM FEATURES ($24.99/mo or $199.99/yr)

- Unlimited journal history and data export
- AI-generated affirmations personalized to your sport
- Weekly performance insight reports
- Competition preparation mode with countdown prompts
- Coach sharing with exportable PDF reports
- Whoop and Apple Health integration (coming soon)

Free users get the complete daily practice with 7-day history and basic streak tracking. No credit card required.

START YOUR PRACTICE TODAY

The best athletes in the world train their minds as deliberately as their bodies. Daily Ritual gives you the structure to do the same -- five minutes in the morning, two minutes after training, three minutes before bed.

Small deposits. Compounding returns.
```

### 1.5 Promotional Text (170 characters, updatable without review)

**Launch version:**
```
Train your mind like you train your body. The first structured journaling app built for athletes. Start your free 7-day premium trial today.
```

**Post-launch rotation options:**
- `New: AI insights now reveal connections between your mental state and training performance. See patterns you can't spot yourself.`
- `Athletes with 30-day streaks report 40% higher training satisfaction. Start building your streak today.`

### 1.6 Category Recommendations

| | Category | Rationale |
|---|----------|-----------|
| **Primary** | Health & Fitness | Where athletes browse. Competitors like Headspace, Strava, and Whoop live here. Best discovery potential. |
| **Secondary** | Lifestyle | Covers the journaling and daily habit angle. Captures users searching for journaling apps. |

### 1.7 Privacy Policy

A privacy policy page already exists at `website/privacy.html`. Ensure it covers:

- [x] What data is collected (journal entries, training data, mood ratings)
- [ ] How AI processes journal content (data sent to Claude API, not used for model training)
- [ ] Third-party integrations (Supabase, Whoop, Apple Health, RevenueCat)
- [ ] Data retention and deletion policy
- [ ] GDPR compliance (right to export, right to delete)
- [ ] Children's privacy (COPPA -- app is not directed at children under 13)

**Required URL for App Store Connect:** `https://dailyritual.app/privacy.html`

### 1.8 Age Rating

**Recommended: 4+**

Questionnaire answers:
- No cartoon/fantasy violence
- No realistic violence
- No sexual content
- No profanity
- No drug/alcohol/tobacco references
- No simulated gambling
- No horror/fear themes
- No medical information (journaling is not medical advice)
- No user-generated content visible to others (private journals)
- No unrestricted web access

**Note:** If coach sharing is introduced with any social features, re-evaluate for 12+ rating.

---

## 2. Screenshot Strategy

### Design Language

All screenshots should follow the app's elite performance design system:
- **Dark mode primary** (deep obsidian background `#0B0C10`)
- **Elite Gold accents** (`#FFE600` neon yellow) for morning/CTAs
- **Champion Blue accents** (`#00BFFF` electric blue) for evening
- **Power Green** (`#39FF14` electric lime) for achievements/completions
- **Typography:** Instrument Sans for headlines, Crimson Pro italic for quotes
- **Device frames:** Minimal black frames, no bezels dominating the image
- **Text overlays:** White headline text on dark gradient overlay above the device

### Mock Data Profile

Use consistent mock data across all screenshots to tell a cohesive story:
- **Athlete:** "Alex M." -- competitive marathon runner
- **Training:** Tuesday track workout, 8x400m intervals
- **Streak:** 23 days
- **Morning goals:** "Hit 74s pace on 400s", "Stay relaxed in final 200m", "Trust the taper"
- **Gratitudes:** "Morning sunlight on the track", "Training partner pushing pace", "Coach believing in me"
- **Affirmation:** "I am prepared. My body is ready. My mind is sharp."
- **Evening mood:** 4/5, training rating 5/5

---

### Screenshot 1: First Impression -- The Dashboard

**Headline text:** `YOUR DAILY PRACTICE`
**Subheadline:** `Structured mental training designed for athletes.`
**App screen:** Today view showing morning ritual card (partially completed with gold checkmarks), training plan card ("Track Workout -- 8x400m"), and evening reflection card (upcoming). Streak badge showing "23" prominently.
**Background:** Gradient from deep obsidian (#0B0C10) at top to subtle gold tint at bottom (eliteGold at 8% opacity)
**Device frame:** iPhone 15 Pro, black titanium, slight angle (5 degrees right tilt)
**Layout:** Device centered in lower 60%, headline text in upper 30%

---

### Screenshot 2: Morning Ritual Flow

**Headline text:** `START WITH INTENTION`
**Subheadline:** `Goals, gratitude, and affirmation in 5 minutes.`
**App screen:** Morning ritual view with goals step active. Three goals filled in: "Hit 74s pace on 400s", "Stay relaxed in final 200m", "Trust the taper". Progress dots at top showing step 1 of 4 active. Gold accent colors throughout.
**Background:** Morning gradient (obsidian to subtle gold tint)
**Device frame:** iPhone 15 Pro, centered, straight-on view
**Layout:** Device in lower 65%, headline text in upper 25%

---

### Screenshot 3: Streak Tracking & Celebrations

**Headline text:** `BUILD THE HABIT`
**Subheadline:** `Every streak started with Day 1.`
**App screen:** Streak celebration animation mid-play. Large "23" day counter with Power Green (#39FF14) glow effect. Calendar heatmap below showing green-filled days. Achievement badge: "3-Week Warrior" with gold border.
**Background:** Deep obsidian with subtle Power Green radial glow behind the device
**Device frame:** iPhone 15 Pro, centered, slight upward perspective
**Layout:** Device in lower 60%, headline text in upper 30%

---

### Screenshot 4: Training Plans & Workout Reflection

**Headline text:** `REFLECT WHILE IT'S FRESH`
**Subheadline:** `Post-workout prompts that sharpen your next session.`
**App screen:** Post-workout reflection view. Training plan card at top: "Track Workout -- 8x400m Intervals" with completed checkmark. Energy rating: 4/5 stars. "What went well" field filled: "Maintained pace through rep 6, relaxed shoulders on final 200m." "What to improve" field: "Start slower on rep 1, save energy for back half."
**Background:** Gradient from obsidian to very subtle Champion Blue tint
**Device frame:** iPhone 15 Pro, centered
**Layout:** Device in lower 65%, headline text in upper 25%

---

### Screenshot 5: Evening Reflection & Insights

**Headline text:** `CLOSE THE LOOP`
**Subheadline:** `Evening reflection + AI insights that spot your patterns.`
**App screen:** Split screen effect or scrolled view showing evening reflection (mood 4/5, "what went well" filled in) AND below it an AI insight card with Champion Blue accent: "Your training satisfaction is 40% higher on days you complete your full morning ritual." Insight has a small brain icon and "Weekly Insight" label.
**Background:** Evening gradient (obsidian to subtle Champion Blue at 8% opacity)
**Device frame:** iPhone 15 Pro, centered
**Layout:** Device in lower 65%, headline text in upper 25%

---

### Screenshot 6 (Optional): Calendar History View

**Headline text:** `SEE YOUR PROGRESS`
**Subheadline:** `Every entry builds the picture of who you're becoming.`
**App screen:** Calendar/history view showing a month grid. Days color-coded: gold dots for morning complete, blue dots for evening complete, green dots for full day. Tapping a date reveals a summary card with that day's goals and mood. Several weeks of consistent entries visible.
**Background:** Neutral gradient (obsidian to secondary background)
**Device frame:** iPhone 15 Pro, centered
**Layout:** Device in lower 60%, headline text in upper 30%

---

### Device Size Requirements

| Size | Devices | Resolution |
|------|---------|------------|
| 6.7" | iPhone 15 Pro Max, 14 Pro Max | 1290 x 2796 px |
| 6.5" | iPhone 11 Pro Max, XS Max | 1242 x 2688 px |
| 5.5" | iPhone 8 Plus, 7 Plus | 1242 x 2208 px |

**Production notes:**
- Create the 6.7" version first as the master, then resize down
- Use Figma or Sketch with the official Apple device frames
- Export at 72 DPI (App Store Connect handles retina)
- Consider a tool like Rotato or Screenshots.pro for 3D device mockups

---

## 3. App Preview Video (30 seconds)

### Storyboard

| Timestamp | Visual | Text Overlay | Audio |
|-----------|--------|-------------|-------|
| 0:00-0:03 | Fade in from black. Phone on dark surface, screen lights up with Daily Ritual logo. | `DAILY RITUAL` | Ambient electronic beat begins (low energy, building) |
| 0:03-0:07 | Quick swipe through morning ritual: goals being typed, gratitude cards appearing with gentle animation. | `5 MINUTES EVERY MORNING` | Beat builds slightly |
| 0:07-0:12 | Training plan card appears with workout details. Cut to post-workout reflection: star rating tapped, text being entered. | `REFLECT AFTER EVERY SESSION` | Rhythm picks up |
| 0:12-0:17 | Evening reflection flow: mood slider, "what went well" text appearing. Completion animation with confetti/glow. | `CLOSE THE LOOP EVERY NIGHT` | Peak energy |
| 0:17-0:22 | Streak counter incrementing from 22 to 23 with celebration animation. Calendar heatmap filling in green. | `BUILD UNBREAKABLE CONSISTENCY` | Sustained energy |
| 0:22-0:26 | AI insight card sliding up: "Your training satisfaction is 40% higher on days you complete morning goals." | `AI THAT UNDERSTANDS ATHLETES` | Begin to resolve |
| 0:26-0:30 | App icon centered on dark background. Tagline appears. | `Train your mind like you train your body.` | Final note, clean ending |

### Production Notes

- **Music:** License a track from Artlist or Epidemic Sound. Search for "motivational ambient electronic" or "athletic minimal." Avoid anything with vocals.
- **Capture method:** Use Xcode's built-in screen recording or QuickTime screen recording with a physical device for the smoothest 60fps capture.
- **Resolution:** 1080 x 1920 (portrait) at 30fps minimum.
- **No voiceover** -- text overlays and the app UI tell the story.
- **Transitions:** Use simple crossfades and slides. No flashy effects that feel cheap.

---

## 4. Pre-Launch Checklist

### 4.1 Technical Requirements

- [ ] **Apple Developer Program** membership active ($99/year)
- [ ] **App Store Connect** record created with bundle ID `revitalized.Your-Daily-Dose`
- [ ] **Distribution certificate** and provisioning profile created for App Store
- [ ] **TestFlight** build uploaded and tested with at least 10 external beta testers
- [ ] **App icon** exported at 1024x1024 (no alpha channel, no rounded corners -- Apple applies these)
- [ ] **Launch screen** configured (currently using default SwiftUI launch)
- [ ] **Push notification certificate** configured for production (currently development in entitlements -- switch `aps-environment` to `production`)
- [ ] **Sign in with Apple** working end-to-end (entitlement already present)
- [ ] **RevenueCat** SDK integrated, products created in App Store Connect, tested in sandbox
- [ ] **Privacy nutrition labels** completed in App Store Connect (see section 4.4)
- [ ] **Support URL** live: `https://dailyritual.app` (already deployed)
- [ ] **Privacy policy URL** live: `https://dailyritual.app/privacy.html` (already deployed)

### 4.2 App Review Guidelines to Watch

| Guideline | Risk Area | Mitigation |
|-----------|-----------|------------|
| **2.3 Accurate Metadata** | Screenshots must represent actual app experience | Use real app screens, not mockups of unreleased features |
| **3.1.1 In-App Purchase** | All premium features must use Apple IAP | Use RevenueCat which routes through StoreKit. Never link to external payment. |
| **3.1.2 Subscriptions** | Must clearly communicate what the user gets and renewal terms | Show price, billing cycle, and what happens when free trial ends on paywall screen |
| **4.0 Design** | App must not feel like a simple web wrapper | Already a native SwiftUI app -- no risk here |
| **5.1.1 Data Collection** | Must disclose all data collection | Complete privacy nutrition labels accurately |
| **5.1.2 Data Use and Sharing** | AI processing of journal content | Disclose that content is processed by AI. Clarify it is not used for training models. |
| **2.1 App Completeness** | App must be fully functional for review | Ensure demo account or clear onboarding so reviewer can test all features |

### 4.3 Common Rejection Reasons & Prevention

1. **"We noticed your app requires users to register before accessing any features."**
   - **Fix:** Allow a preview of the morning ritual structure (read-only sample) before requiring sign-up. Or provide a guest/skip option during onboarding.

2. **"Your app's in-app purchase doesn't clearly communicate the subscription terms."**
   - **Fix:** On the paywall, display: price per month, price per year, free trial length, and the sentence "Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless canceled at least 24 hours before the end of the current period."

3. **"We found that your app crashed during our review."**
   - **Fix:** Test on the oldest supported iOS version (18.5). Test with no network connection. Test the full flow from fresh install.

4. **"Your app uses background modes but does not appear to need them."**
   - **Fix:** Background mode `remote-notification` is justified for morning/evening reminders and post-workout prompts. Document this in the review notes.

### 4.4 Privacy Nutrition Labels

Configure these in App Store Connect under "App Privacy":

**Data Collected:**

| Data Type | Collection | Linked to Identity | Tracking |
|-----------|------------|-------------------|----------|
| Name | Yes | Yes | No |
| Email Address | Yes | Yes | No |
| Health & Fitness (mood, workout ratings) | Yes | Yes | No |
| User Content (journal entries, goals, gratitudes) | Yes | Yes | No |
| Identifiers (user ID) | Yes | Yes | No |
| Usage Data (app interactions) | Yes | No | No |
| Diagnostics (crash logs) | Yes | No | No |

**Purpose declarations:**
- Name/Email: App Functionality (account creation, authentication)
- Health & Fitness: App Functionality (mood tracking, workout reflection)
- User Content: App Functionality (journaling features)
- Identifiers: App Functionality (Supabase auth)
- Usage Data: Analytics (improving the app)
- Diagnostics: App Functionality (crash reporting)

### 4.5 In-App Purchase Configuration

Create these products in App Store Connect:

| Product ID | Type | Price | Display Name |
|------------|------|-------|-------------|
| `com.dailyritual.premium.monthly` | Auto-Renewable Subscription | $24.99/mo | Daily Ritual Premium (Monthly) |
| `com.dailyritual.premium.annual` | Auto-Renewable Subscription | $199.99/yr | Daily Ritual Premium (Annual) |

**Subscription Group:** "Daily Ritual Premium"
**Free Trial:** 7 days on both monthly and annual
**Grace Period:** Enable 16-day billing grace period (reduces involuntary churn)
**Introductory Offer:** 7-day free trial (primary), consider a $9.99 first-month offer for A/B testing later

---

## 5. Launch Marketing Plan

### Week -4 to -1: Pre-Launch

#### Landing Page Updates
- [ ] Update `website/index.html` waitlist CTA to "Download on the App Store" with badge (day of launch)
- [ ] Add app preview screenshots to the landing page
- [ ] Add a "Coming [launch date]" countdown banner
- [ ] Create a `/launch` page with full feature breakdown and press kit download

#### Social Media Teasers (2 posts/week)

**Week -4:**
- Post 1: "We've been building something for athletes who take mental training seriously. More soon." + dark teaser image with Daily Ritual logo
- Post 2: Behind-the-scenes screenshot of the morning ritual UI (blurred slightly) + "Structured. Not generic."

**Week -3:**
- Post 1: Quote graphic -- "Your physical training is structured, tracked, and optimized. Your mental training should be too."
- Post 2: Short video clip of streak animation + "23 days and counting. What's your longest mental training streak?"

**Week -2:**
- Post 1: Feature reveal -- AI insight card screenshot + "AI that understands athletes, not just users."
- Post 2: Comparison graphic -- "Generic journaling apps vs. Daily Ritual" (side by side: blank page vs. structured prompts)

**Week -1:**
- Post 1: "Launching [date]. Join the first wave." + App Store badge
- Post 2: Testimonial from beta tester (get one strong quote from TestFlight users)

#### Beta Tester Recruitment (Target: 50 testers)

| Channel | Approach | Expected Testers |
|---------|----------|-----------------|
| Existing waitlist | Email blast: "Want early access? Reply for TestFlight invite" | 15-20 |
| Reddit r/running | Post: "Built a mental training app for runners -- looking for beta testers" | 10-15 |
| Strava clubs | Direct message club admins in local running/tri clubs | 5-10 |
| Twitter/X | Post with #RunningCommunity #TriTraining hashtags | 5-10 |
| Friends/network | Personal outreach to athlete friends | 5-10 |

#### Athlete Micro-Influencer Outreach (5-50K followers)

Target list by sport:

| Sport | Platform | Account Types to Target |
|-------|----------|------------------------|
| Running | Instagram, Strava | Marathon coaches, sub-elite runners, running content creators |
| Triathlon | Instagram, YouTube | Age-group triathletes, Ironman finishers, tri coaches |
| CrossFit | Instagram, TikTok | Box owners, competitive athletes, programming coaches |
| Swimming | Instagram, YouTube | Masters swimmers, college swimmers, swim coaches |
| Cycling | Strava, YouTube | Gran fondo riders, crit racers, bike-fit specialists |

**Outreach template:**
```
Hey [Name] -- I've been following your training and love your approach to
[specific thing they do]. I built an app called Daily Ritual -- it's a
structured mental training journal specifically for athletes like you.

Think: morning intention setting, post-workout reflection prompts, streak
tracking, and AI that connects your mental state to training performance.

Would you be open to trying it for 2 weeks and sharing your honest thoughts?
Happy to give you a free premium account. No strings attached -- if it doesn't
add value to your training, no pressure to post anything.
```

#### Reddit Community Engagement (start Week -3)

**Strategy:** Provide genuine value first, mention app only when directly relevant.

| Subreddit | Engagement Plan |
|-----------|----------------|
| r/running | Comment on mental training threads. Post value content: "The 5-minute pre-run ritual that changed my training" |
| r/triathlon | Engage in race prep discussions. Comment about mental game for Ironman |
| r/CrossFit | Discuss competition mindset, post about structured reflection after WODs |
| r/swimming | Contribute to threads about race anxiety, pre-meet routines |
| r/AdvancedRunning | Higher-level discussion about mental training periodization |
| r/artc | Share data-driven insights about mood and training correlations |

**Rules:**
- 10:1 ratio -- 10 value comments for every 1 mention of the app
- Never spam. Never self-promote in a way that feels forced.
- If someone asks "is there an app for this?" -- that is the moment.

---

### Launch Week: Day-by-Day Playbook

#### Day -1 (Night Before)

- [ ] Verify app is approved and ready for sale in App Store Connect
- [ ] Schedule release for manual (not automatic) so you control the exact moment
- [ ] Pre-write all social posts and load into scheduling tool
- [ ] Email waitlist: "Tomorrow. 8 AM EST. Daily Ritual launches."
- [ ] Prepare Product Hunt listing (draft, screenshots, maker comment)

#### Launch Day (Day 0)

**6:00 AM EST**
- [ ] Release app on App Store (press "Release This Version" in App Store Connect)
- [ ] Verify app appears in search and download works

**8:00 AM EST**
- [ ] Send waitlist email: "Daily Ritual is live. Download now." with direct App Store link
- [ ] Post on Twitter/X: "Daily Ritual is live. Train your mind like you train your body. The first structured journaling app built for athletes. [App Store link]"
- [ ] Post on Instagram: Carousel of 3 screenshots + "Link in bio"
- [ ] Submit to Product Hunt (or schedule for the following Tuesday if launch day is not Tuesday)

**10:00 AM EST**
- [ ] Post on Reddit r/running: "I built a mental training app for runners -- here's what it does and why" (genuine, story-driven post, NOT a sales pitch)
- [ ] Post on Reddit r/triathlon: Similar authentic post tailored to multi-sport
- [ ] Email influencers who got early access: "We're live! Would love your honest take if you've been using it."

**2:00 PM EST**
- [ ] Share on LinkedIn (personal story angle: "Why I built a mental training app for athletes")
- [ ] Cross-post to relevant Facebook groups (running clubs, tri groups)
- [ ] Reply to every Product Hunt comment and upvote

**6:00 PM EST**
- [ ] Check first-day metrics: downloads, signups, morning ritual completions
- [ ] Respond to any App Store reviews (even just "thank you!")
- [ ] Post Instagram Story: "Day 1 numbers" or behind-the-scenes of launch day

#### Day 1-3

- [ ] Monitor crash reports (Xcode Organizer, any crash reporting service)
- [ ] Respond to every review and support email within 4 hours
- [ ] Post daily on social: user milestones, feature highlights, behind-the-scenes
- [ ] Submit to additional directories: AlternativeTo, SaaSHub, AppAdvice

#### Day 4-7

- [ ] Publish blog post: "Why I Built Daily Ritual" (personal founder story)
- [ ] Reach out to running/fitness podcasts for guest appearances
- [ ] Analyze first-week conversion funnel: install > signup > morning ritual > day 2 retention
- [ ] A/B test promotional text based on which message drove most downloads

### Launch Week Social Posts

**Twitter/X Launch Thread:**
```
1/ Today I'm launching Daily Ritual -- the first journaling app built
specifically for athletes.

Here's why it exists and what it does. (thread)

2/ I've trained competitively for [X] years. Physical training is
structured: periodization, progressive overload, recovery protocols.

Mental training? "Just journal."

That's like telling someone to "just run more" when they ask for a
marathon plan.

3/ Daily Ritual gives your mental training the same structure:

Morning: 3 goals + gratitude + personalized affirmation (5 min)
Post-workout: Reflect while it's fresh (2 min)
Evening: Close the loop -- mood, wins, growth areas (3 min)

4/ The AI doesn't give generic advice. It learns YOUR patterns:

"Your best training days follow mornings where you set process goals,
not outcome goals."

"Your mood drops after rest days -- but your performance peaks 2 days
after them."

5/ Built for runners, swimmers, cyclists, CrossFitters, triathletes --
any athlete who tracks their body but not their mind.

Free to try. Premium for AI insights and unlimited history.

Download: [App Store Link]
```

**Reddit Post Template (r/running):**
```
Title: I built a structured mental training app for runners -- here's
why "just journal" doesn't work

Hey r/running -- long-time lurker, first time posting about something
I built.

I've been running for [X] years and always knew mental training
mattered. Every coach says "keep a journal" but nobody tells you WHAT
to write or WHEN to write it.

So I built Daily Ritual. It's a structured daily practice:
- Morning: Set 3 goals, write 3 gratitudes, get a personalized
  affirmation (5 min)
- After your run: Rate your energy, write what went well and what
  to improve (2 min)
- Evening: Mood check, wins, areas for growth (3 min)

Over time, the AI finds patterns -- like whether your best runs
correlate with certain morning mindsets, or if your mood dips after
specific workout types.

It's free to use (premium unlocks AI insights and full history).
Just launched today on iOS.

Would genuinely love feedback from this community -- you all are
the target audience and I want to build something that actually helps.

[App Store Link]

Happy to answer any questions about the app or the thinking behind it.
```

### Product Hunt Launch Strategy

**Timing:** Launch on a Tuesday or Wednesday (highest traffic days)

**Listing:**
- **Tagline:** "Train your mind like you train your body"
- **Description:** Focus on the problem (athletes have structured physical training but unstructured mental training) and the unique solution (structured daily practice with AI insights)
- **First comment (Maker):** Personal story about why you built it, what makes it different from generic journaling apps, and an honest call for feedback
- **Images:** 4-5 screenshots showing the flow: dashboard > morning ritual > workout reflection > AI insight
- **Topics:** Productivity, Health & Fitness, Artificial Intelligence

**Day-of tactics:**
- Share PH link with waitlist, beta testers, and friends early in the day
- Be online and responding to every comment for the first 8 hours
- Cross-post PH link to Twitter and LinkedIn

---

### Weeks 1-4: Post-Launch

#### ASO Optimization (Week 2-3)

After 2 weeks of data:
- Check Search Ads keyword impression share in App Store Connect
- Review which keywords are driving impressions vs. downloads
- Adjust keyword field based on actual search data
- Test subtitle variations (if doing an update)
- Monitor category ranking and adjust primary/secondary if needed

**Tools:** AppFollow, Sensor Tower (free tiers), or App Store Connect's built-in analytics

#### Review Solicitation Strategy

**In-app review prompt triggers (use SKStoreReviewController):**
- After completing their 7th consecutive daily ritual (strong positive moment)
- After receiving their first AI insight (moment of delight)
- After hitting a 14-day streak (proven engagement)

**Rules:**
- Never prompt more than 3 times per 365-day period (Apple's limit)
- Never prompt during the ritual flow (interrupts the experience)
- Only prompt after a positive completion moment
- Add a "Love Daily Ritual? Leave a review" link in Settings for manual access

**Target:** 50 ratings in first month, 4.5+ star average

#### Content Marketing Topics (blog at dailyritual.app/blog)

| Week | Topic | SEO Target |
|------|-------|------------|
| 1 | "Why Athletes Need Structured Journaling (Not Blank Pages)" | mental training for athletes |
| 2 | "The 5-Minute Morning Ritual That Improves Training Performance" | morning routine for athletes |
| 3 | "How to Reflect After a Bad Workout Without Spiraling" | post-workout reflection |
| 4 | "Gratitude Practice for Athletes: Why It Works and How to Start" | gratitude practice athletes |

#### Paid Acquisition Channels to Test (Month 2)

| Channel | Budget | Target CPI | Notes |
|---------|--------|-----------|-------|
| Apple Search Ads | $500/mo | <$3.00 | Start with exact match on "athlete journal", "mental training app", "sports journal" |
| Instagram Ads | $300/mo | <$4.00 | Target interests: marathon running, triathlon, CrossFit + lookalike from waitlist emails |
| Podcast Sponsorships | $200-500/episode | N/A | Start with 1-2 niche running podcasts. Provide unique promo code for tracking. |

#### Metrics to Track and Targets

| Metric | Week 1 Target | Month 1 Target | Tool |
|--------|--------------|----------------|------|
| Downloads | 200 | 800 | App Store Connect |
| Signups (accounts created) | 150 | 600 | Supabase / PostHog |
| Day 1 retention | >60% | >60% | PostHog |
| Day 7 retention | >30% | >35% | PostHog |
| Morning ritual completion rate | >50% of DAU | >55% | Backend analytics |
| Free trial starts | 100 | 400 | RevenueCat |
| Trial > Paid conversion | >15% | >12% | RevenueCat |
| MRR | -- | $500+ | RevenueCat |
| App Store rating | 4.5+ | 4.5+ | App Store Connect |
| Crash-free rate | >99.5% | >99.5% | Xcode Organizer |

---

## 6. Pricing Strategy

### 6.1 Free Tier

| Feature | Free | Premium |
|---------|------|---------|
| Morning ritual (goals, gratitude, affirmation) | Full access | Full access |
| Evening reflection | Full access | Full access |
| Post-workout reflection | Full access | Full access |
| Streak tracking | Basic (current streak only) | Full history + streaks for each ritual type |
| Journal history | 7 days | Unlimited |
| AI affirmations | Generic (not personalized) | Personalized to sport + patterns |
| AI weekly insights | None | Full weekly reports |
| Competition prep mode | None | Full countdown + tailored prompts |
| Data export (PDF) | None | Full export |
| Coach sharing | None | Exportable reports |
| Integrations (Whoop, Apple Health) | None | Full access |

**Rationale:** Free tier is generous enough to form the habit (the full daily practice), but limited enough that serious athletes feel the pain of missing insights and history.

### 6.2 Premium Pricing

| Plan | Price | Effective Monthly | Annual Savings |
|------|-------|-------------------|----------------|
| Monthly | $24.99/mo | $24.99 | -- |
| Annual | $199.99/yr | $16.67/mo | 33% ($99.89 saved) |

**Pricing rationale:**
- Athletes already pay $30/mo for Whoop, $15/mo for TrainingPeaks, $10/mo for Strava Premium
- $24.99/mo positions Daily Ritual as a serious performance tool, not a throwaway app
- The annual plan at $199.99 is a strong anchor -- "Less than the cost of one pair of racing shoes per year"

### 6.3 Free Trial Configuration

- **Duration:** 7 days of full Premium access
- **Trigger:** Immediately after account creation
- **Communication:** "Your 7-day Premium trial is active. After the trial, you'll still have full access to the daily practice -- just with limited history and no AI insights."
- **Trial end notification:** Push notification on Day 6: "Your Premium trial ends tomorrow. Keep your insights and history -- upgrade now."
- **No credit card required** for trial (reduces friction, Apple handles billing)

### 6.4 RevenueCat Setup Checklist

- [ ] Create RevenueCat account and project
- [ ] Add App Store Connect API key to RevenueCat
- [ ] Create "Entitlements" > `premium`
- [ ] Create "Products" > `com.dailyritual.premium.monthly` and `com.dailyritual.premium.annual`
- [ ] Create "Offering" > `default` with both products
- [ ] Integrate Purchases SDK in iOS app (add to Swift Package Manager)
- [ ] Configure paywall to show both options with annual highlighted as "Best Value"
- [ ] Test in sandbox: purchase, restore, cancel, re-subscribe
- [ ] Set up webhook to Supabase to update `is_premium` on user record
- [ ] Enable RevenueCat Charts for MRR, trial conversion, and churn dashboards

---

## 7. Competitive Positioning

### 7.1 Key Competitors

| App | Category | Price | Strength | Weakness vs. Daily Ritual |
|-----|----------|-------|----------|---------------------------|
| **Day One** | General journaling | $4.17/mo | Beautiful UI, markdown, photo journals | No athletic structure, no workout integration, no AI insights |
| **Headspace** | Meditation | $12.99/mo | Massive brand, guided meditation library | Meditation-only, no journaling, no workout connection, no reflection structure |
| **Calm** | Meditation/Sleep | $14.99/mo | Sleep stories, celebrity voices | Same as Headspace -- no journaling, no athlete focus |
| **TrainingPeaks** | Training planning | $19.95/mo | Detailed workout planning, coach integration | Physical metrics only, no mental training, no journaling |
| **Strava** | Social fitness | $11.99/mo | Social motivation, route tracking, massive community | No mental component at all, purely physical tracking |
| **Whoop** | Recovery/strain | $30/mo + band | Excellent biometric data, recovery scores | No mental layer, no journaling, no reflection prompts |
| **Champion's Mind** | Sport psychology | $11.99/mo | PhD-backed mental skills training | Audio-only, no journaling, no workout integration, not personalized |

### 7.2 Positioning Matrix

```
                    ATHLETE-SPECIFIC
                          |
              Daily Ritual |  TrainingPeaks
                     *     |     *
                           |
   MENTAL ─────────────────┼───────────────── PHYSICAL
   TRAINING                |                  TRAINING
                           |
        Headspace *        |     * Strava
            Calm *         |     * Whoop
                           |
                    GENERAL AUDIENCE
```

Daily Ritual is the only product in the upper-left quadrant: athlete-specific AND mental training focused.

### 7.3 Differentiation Messaging

**Against general journaling apps (Day One, Journey):**
> "You wouldn't follow a generic workout plan designed for everyone. Why would you use a generic journal? Daily Ritual gives your mental training the same structure as your physical training -- because athletes aren't general users."

**Against meditation apps (Headspace, Calm):**
> "Meditation is one tool. Daily Ritual is the full practice -- intention setting, workout reflection, pattern recognition, and AI that connects your mind to your training. It's not about being calm. It's about performing."

**Against fitness trackers (Strava, Whoop, TrainingPeaks):**
> "Your watch tracks your body. Daily Ritual tracks your mind. Together, you see the full picture of performance -- because a 5/5 training day isn't just about heart rate zones."

**Against sport psychology apps (Champion's Mind):**
> "Sport psychology content teaches you the theory. Daily Ritual is the daily practice. It's the difference between reading about training and actually lacing up your shoes."

### 7.4 One-Line Positioning Statement

> Daily Ritual is the structured daily mental training practice for athletes who already take their physical training seriously -- connecting mindset, workouts, and AI insights in one app designed for the athlete's rhythm.

---

## Appendix A: Press Release Template

```
FOR IMMEDIATE RELEASE

Daily Ritual Launches: The First Structured Mental Training App
Built Specifically for Athletes

[City, Date] -- Daily Ritual, a new iOS app, launched today with a
mission to bring the same structure and intentionality to mental
training that athletes already apply to their physical training.

"Every serious athlete has a training plan. But when it comes to
mental training, the best advice is 'keep a journal' -- with no
structure, no prompts, and no connection to their actual training,"
said [Founder Name], creator of Daily Ritual. "We built the app
we wished existed."

Daily Ritual provides a structured daily practice consisting of a
5-minute morning ritual (goal setting, gratitude, personalized
affirmation), post-workout reflection prompts triggered after
training sessions, and an evening reflection to close the loop.
Over time, AI analyzes patterns and surfaces insights connecting
mental state to training performance.

The app is available now on the iOS App Store with a free tier
and 7-day Premium trial. Premium subscriptions are $24.99/month
or $199.99/year.

Download: [App Store Link]
Website: https://dailyritual.app
Press Kit: https://dailyritual.app/press

###

Media Contact:
[Name]
[Email]
[Phone]
```

---

## Appendix B: Launch Timeline Summary

| Week | Focus | Key Deliverables |
|------|-------|-----------------|
| **-4** | Pre-launch prep | TestFlight beta live, influencer outreach begins, social teasers start |
| **-3** | Community seeding | Reddit engagement begins, beta feedback incorporated, screenshots finalized |
| **-2** | App Store prep | App Store listing complete, screenshots uploaded, review submitted |
| **-1** | Final prep | Waitlist primed, social posts scheduled, Product Hunt drafted, press release ready |
| **0** | LAUNCH | App live, emails sent, social blitz, Product Hunt, Reddit posts |
| **+1** | Momentum | Respond to reviews, analyze data, blog post #1, podcast outreach |
| **+2** | Optimize | ASO adjustments based on data, review solicitation active, content marketing |
| **+3** | Expand | Paid acquisition testing, influencer content going live, second Reddit wave |
| **+4** | Iterate | Feature update based on user feedback, conversion funnel optimization, pricing validation |

---

*This document should be treated as a living playbook. Update targets and tactics as real data comes in after launch.*
