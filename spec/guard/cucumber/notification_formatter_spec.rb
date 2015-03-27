require "guard/cucumber/notification_formatter"

RSpec.describe Guard::Cucumber::NotificationFormatter do
  subject { described_class.new(mother, nil, {}) }
  let(:mother) { instance_double(Cucumber::Runtime) }

  context "after all features" do
    let(:step) { double("step") }
    let(:step_match) { double("step_match") }
    let(:feature_element) { double("feature_element") }
    let(:file) { double("file") }

    before do
      allow(mother).to receive(:steps).with(:passed).and_return([step])
      allow(mother).to receive(:steps).with(:pending).and_return([step])
      allow(mother).to receive(:steps).with(:undefined).and_return([step])
      allow(mother).to receive(:steps).with(:skipped).and_return([step])
      allow(mother).to receive(:steps).with(:failed).and_return([step])
    end

    it "formats the notification" do
      allow(Guard::Compat::UI).to receive(:notify).
        with("1 failed step, 1 skipped step, 1 undefined step, 1 pending " +
             "step, 1 passed step", title: "Cucumber Results", image: :failed)

      subject.after_features(nil)
    end

    before { ENV["GUARD_CUCUMBER_RERUN_FILE"] = "foo/bar.txt" }
    after { ENV.delete "GUARD_CUCUMBER_RERUN_FILE" }

    it "writes to the rerun file" do
      allow(Guard::Compat::UI).to receive(:notify)
      allow(step_match).to receive(:format_args)
      subject.step_name(nil, step_match, :failed, nil, nil, nil)
      expect(file).to receive(:puts).with("features/foo")
      expect(File).to receive(:open).with("foo/bar.txt", "w").and_yield(file)
      allow(feature_element).to receive(:location).and_return("features/foo")
      subject.after_feature_element(feature_element)
      subject.after_features(nil)
    end
  end

  describe "#step_name" do
    context "when failure is in a background step" do
      let(:step_match) { instance_double(Cucumber::StepMatch) }
      let(:feature) { instance_double(Cucumber::Ast::Feature, name: "feature1") }
      let(:background) { instance_double(Cucumber::Ast::Background, feature: feature) }

      before do
        subject.before_background(background)
        allow(step_match).to receive(:format_args) do |block|
          block.call "step_name1"
        end
      end

      it "notifies with a valid feature name" do
        expect(Guard::Compat::UI).to receive(:notify).with("*step_name1*", hash_including(title: "feature1"))
        subject.step_name(nil, step_match, :failed, nil, nil, nil)
      end
    end
  end
end
