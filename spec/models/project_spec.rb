require "rails_helper"

RSpec.describe Project, type: :model do
  subject { create(:project) }

  it { should have_many(:projects).dependent(:destroy) }
  it { should validate_presence_of(:title) }
  it { should have_many(:stories) }
  it { should belong_to(:parent) }

  it "does not set a position if not a sub project" do
    parent = create(:project)
    expect(parent.position).to be_nil
  end

  context "#has_parent?" do
    it "returns true if project has a parent" do
      parent = create(:project)
      child = create(:project, parent: parent)
      expect(child.has_parent?).to be_truthy
    end

    it "returns false if project doesn't have a parent" do
      parent = create(:project)
      expect(parent.has_parent?).to be_falsey
    end
  end

  it "sets a position scoped within a parent" do
    parent = create(:project)
    sub_project1 = create(:project, parent: parent)
    sub_project2 = create(:project, parent: parent)
    expect(sub_project1.position).to eq 1
    expect(sub_project2.position).to eq 2
  end

  describe ".with_ordered_descendents" do
    it "orders sub projects properly" do
      parent = create(:project)
      sub_project1 = create(:project, parent: parent, position: 2)
      story_5 = create(:story, project: sub_project1, position: 2)
      story_4 = create(:story, project: sub_project1, position: 1)
      story_6 = create(:story, project: sub_project1, position: 3)
      sub_project2 = create(:project, parent: parent, position: 1)
      story_3 = create(:story, project: sub_project2, position: 3)
      story_1 = create(:story, project: sub_project2, position: 1)
      story_2 = create(:story, project: sub_project2, position: 2)
      sub_projects = Project.sub_projects_with_ordered_stories(parent.id)

      expect(sub_projects.count).to eq 2
      expect(sub_projects[0].id).to eq sub_project2.id
      expect(sub_projects[0].stories[0].id).to eq story_1.id
      expect(sub_projects[0].stories[1].id).to eq story_2.id
      expect(sub_projects[0].stories[2].id).to eq story_3.id
      expect(sub_projects[1].id).to eq sub_project1.id
      expect(sub_projects[1].stories[0].id).to eq story_4.id
      expect(sub_projects[1].stories[1].id).to eq story_5.id
      expect(sub_projects[1].stories[2].id).to eq story_6.id
    end
  end
end
