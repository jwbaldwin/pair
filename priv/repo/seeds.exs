# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Pair.Repo.insert!(%Pair.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Pair.Recordings.Recording
alias Pair.MeetingTemplates.MeetingTemplate
alias Pair.Repo

transcript = """
Sarah: Hi Emily! Thanks for scheduling this call. I wanted to go over the timeline and some final details for your wedding next month.

Emily: Of course! Michael and I are so excited. We've been looking forward to this conversation.

Michael: Yeah, we really want to make sure we capture all the important moments, especially since we have family coming from overseas.

Sarah: Absolutely. So your ceremony is on Saturday, June 15th at 2 PM at the Botanical Gardens, correct?

Emily: That's right. We're expecting about 120 guests.

Sarah: Perfect. I typically arrive about 90 minutes before the ceremony to capture getting-ready shots. Would you be comfortable with me starting around 12:30 PM?

Emily: That works great. I'll be at the bridal suite at the gardens, and Michael will be in the groom's room.

Michael: Actually, Sarah, we wanted to ask about the first look. We've been going back and forth on whether to do it.

Sarah: I always recommend it, but it's completely your choice. It gives us a private moment to capture your reactions, and it actually helps with timeline since we can do couple portraits before the ceremony.

Emily: We've decided we want to do it. Where would be the best spot?

Sarah: There's a beautiful secluded garden area behind the main pavilion. It has great natural light around 1:15 PM, and it's private from guests.

Michael: That sounds perfect. What about family photos? My grandmother is 89 and we really want to make sure she's comfortable.

Sarah: We'll absolutely prioritize family photos right after the ceremony. I suggest we do immediate family first - parents, grandparents, siblings - then extend to aunts, uncles, cousins. Should take about 20 minutes total.

Emily: That's exactly what we were hoping for. Oh, and we definitely want photos during cocktail hour. Some of our friends are flying in from different countries and we want candid shots of everyone reconnecting.

Sarah: Absolutely. I love capturing those natural moments. The cocktail hour is from 5 to 6 PM, right? I'll focus on guest interactions, detail shots of the venue setup, and any special moments.

Michael: Yes, that's right. The reception starts at 6 PM. We're doing speeches after dinner around 7:30 PM.

Sarah: Perfect. For speeches, I'll position myself to capture both the speakers and your reactions. Are there any specific moments during the reception you definitely want captured?

Emily: The cake cutting, our first dance, and when we do the anniversary dance where all the married couples join us on the dance floor.

Sarah: Those are all must-haves. What about the bouquet and garter toss?

Emily: We're skipping the garter toss, but definitely doing the bouquet toss.

Michael: One thing we're worried about is the weather. It's been pretty unpredictable lately.

Sarah: Don't worry, I always have backup plans. The gardens have a beautiful covered pavilion, and I bring lighting equipment for indoor shots. Rain can actually create some stunning romantic photos if you're up for it.

Emily: That makes me feel so much better. What about the timeline for editing and getting our photos back?

Sarah: You'll receive a sneak peek gallery with 15-20 edited highlights within 48 hours. The full gallery of 400-500 edited photos will be ready within 4 weeks. I'll also create a slideshow for you to share with family.

Michael: That's amazing. We're leaving for our honeymoon to Italy on June 22nd, so having some photos to share before then would be incredible.

Sarah: Absolutely, the sneak peeks will definitely be ready before you leave. Is there anything specific about your relationship or wedding style you want me to capture?

Emily: We're pretty casual and fun-loving. We don't want super formal, posed shots. We want the photos to feel authentic and joyful.

Sarah: That's exactly my style. I focus on photojournalistic storytelling with natural emotions. I'll guide you through poses, but they'll feel relaxed and genuine.

Michael: One last question - what if we want to add an engagement session or bridal portraits?

Sarah: We can definitely add those! An engagement session would be $400 and we could do it at the gardens or another location. Bridal portraits would be $300 and could be done a week before the wedding.

Emily: Let's think about the engagement session. We'll let you know by next week.

Sarah: Perfect. I'll send you a detailed timeline and shot list after this call, and we'll do a final check-in call the week before the wedding.

Michael: This has been so helpful. We feel much more prepared and excited now.

Sarah: I'm so excited to capture your special day! It's going to be absolutely beautiful.
"""

insights = """
- Photographer to arrive at 12:30 PM for getting-ready shots (90 minutes before ceremony)
- Schedule first look at 1:15 PM in secluded garden area behind main pavilion
- Prioritize immediate family photos after ceremony (20 minutes total)
- Capture candid moments during cocktail hour (5-6 PM) focusing on guest interactions
- Position for speeches after dinner (7:30 PM) to capture speakers and couple reactions
- Must-capture moments: cake cutting, first dance, anniversary dance, bouquet toss
- Deliver sneak peek gallery (15-20 photos) within 48 hours
- Full gallery (400-500 edited photos) ready within 4 weeks
- Create slideshow for family sharing
- Send detailed timeline and shot list after call
- Schedule final check-in call the week before wedding
- Follow up on engagement session decision by next week ($400 if added)
- Backup plans prepared for weather including covered pavilion and lighting equipment
- Focus on photojournalistic, natural style per couple's preference
"""

meeting_notes_json =
  Jason.encode!(%{
    meeting_metadata: %{
      meeting_type: "Wedding Photography Consultation",
      primary_topic: "Timeline planning and detail coordination for June 15th wedding"
    },
    participants: [
      %{name: "Sarah", role: "Wedding Photographer"},
      %{name: "Emily", role: "Bride"},
      %{name: "Michael", role: "Groom"}
    ],
    sections: [
      %{
        title: "Event Overview",
        type: "overview",
        content: [
          "Wedding date: Saturday, June 15th at 2 PM",
          "Venue: Botanical Gardens",
          "Guest count: 120 attendees",
          "Family traveling from overseas",
          "Reception starts at 6 PM"
        ]
      },
      %{
        title: "Photography Timeline",
        type: "timeline",
        content: [
          "12:30 PM - Photographer arrival for getting-ready shots",
          "1:15 PM - First look in secluded garden area",
          "2:00 PM - Ceremony begins",
          "Immediate post-ceremony - Family photos (20 minutes)",
          "5:00-6:00 PM - Cocktail hour candid shots",
          "7:30 PM - Speeches photography"
        ]
      },
      %{
        title: "Key Decisions Made",
        type: "decisions",
        content: [
          "First look will be conducted before ceremony",
          "Family photos prioritized immediately after ceremony",
          "Grandmother (89) to be accommodated in family photo timeline",
          "Skipping garter toss, keeping bouquet toss",
          "Focus on natural, photojournalistic style"
        ]
      },
      %{
        title: "Must-Capture Moments",
        type: "requirements",
        content: [
          "Getting-ready shots in bridal and groom suites",
          "First look reactions",
          "Immediate family photos (priority for elderly grandmother)",
          "Guest interactions during cocktail hour",
          "Speeches and couple reactions",
          "Cake cutting ceremony",
          "First dance as married couple",
          "Anniversary dance with all married couples",
          "Bouquet toss"
        ]
      },
      %{
        title: "Delivery Timeline",
        type: "timeline",
        content: [
          "Sneak peek gallery (15-20 photos) within 48 hours",
          "Full gallery (400-500 edited photos) within 4 weeks",
          "Slideshow creation for family sharing",
          "Photos needed before June 22nd honeymoon departure"
        ]
      },
      %{
        title: "Weather Contingency",
        type: "concerns",
        content: [
          "Backup covered pavilion available at venue",
          "Photographer brings lighting equipment for indoor shots",
          "Rain photography option discussed as potentially romantic"
        ]
      },
      %{
        title: "Next Steps",
        type: "action_items",
        content: [
          "Sarah to send detailed timeline and shot list",
          "Final check-in call scheduled for week before wedding",
          "Emily and Michael to decide on engagement session by next week",
          "Engagement session available for $400 if desired",
          "Bridal portraits available for $300 if interested"
        ]
      },
      %{
        title: "Additional Services Discussed",
        type: "budget",
        content: [
          "Optional engagement session: $400",
          "Optional bridal portraits: $300",
          "Both services pending couple's decision"
        ]
      }
    ]
  })

%MeetingTemplate{}
|> MeetingTemplate.changeset(%{
  name: "Initial Inquiry",
  description: """
  This template is designed for wedding photographers conducting initial consultation calls with potential clients - sort of a two way interview.
  Focus on extracting key details about the client, their preferences and the vibe they want for their wedding.
  Pay special attention to stylistic details, personal preferences and likes-dislikes, or details around pricing and length of coverage.
  Include specific quotes, numbers, dates, and pricing when mentioned.
  """,
  sections: [
    "About the client",
    "Wedding vision",
    "Venue, and wedding details",
    "Pricing & additional services",
    "Next steps & follow-upaActions"
  ],
  is_system_template: true
})
|> Repo.insert!()

%Recording{}
|> Recording.changeset(%{
  upload_url: "/uploads/wedding_consultation_emily_michael_2024.wav",
  transcription: transcript,
  actions: insights,
  meeting_notes: meeting_notes_json,
  status: :completed
})
|> Repo.insert!()
