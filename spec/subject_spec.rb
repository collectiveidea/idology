require 'spec_helper'

include IDology

share_examples_for "Any Request" do
  it "should be able to locate a person" do
    @result.should_not be_false
  end

  it "should set the ID" do
    @subject.idNumber.should == 5342889
  end

  it "should set any qualifiers" do
    expected = %w(resultcode.dob.does.not.match resultcode.address.does.not.match)
    @subject.qualifiers.map(&:key).to_set.should == expected.to_set
  end
end

describe Subject do
  
  before do
    FakeWeb.clean_registry
    IDology[:username] = 'fake'
    IDology[:password] = 'fake'
  end
  
  describe "locate" do
    
    describe "with a match" do
      before do
        fake_idology(:search, 'match_found_response')
        @subject = Subject.new
        @result = @subject.locate
      end
    
      it_should_behave_like "Any Request"
      
      it "should know if the subject is eligible for verification questions" do
        @subject.eligible_for_verification.should be_true
      end
    end
    
    it "should be false when it cannot locate" do
      fake_idology(:search, 'no_match_response')
      
      subject = Subject.new
      subject.locate.should be_false      
    end
    
  end
  
  describe 'get_questions' do
    before do
      fake_idology(:questions, 'questions_response')
      @subject = Subject.new
      @result = @subject.get_questions
    end
    
    it_should_behave_like "Any Request"
    
    it "should set the verification questions" do
      q = @subject.verification_questions.detect{|q| q.prompt == 'With which name are you associated?'}
      q.should_not be_blank
      q.answers.should == ['ENDO', 'ENRIQUEZ', 'EATON', 'ECHOLS', 'EPPS', 'None of the above']
    end
  end
  
  describe 'submit_answers' do
    before do
      fake_idology(:questions, 'questions_response')      
      fake_idology(:answers, 'all_answers_correct_response')
      @subject = Subject.new
      @subject.get_questions
      @result = @subject.submit_answers
    end
    
    it_should_behave_like "Any Request"
    
    it "should set the verified flag" do
      @subject.verified.should be_true
    end
    
    it "should set the challenge flag" do
      @subject.verified.should be_true
    end
  end
  
  describe 'get_challenge_questions' do
    before do
      fake_idology(:challenge_questions, 'challenge_questions_response')
      @subject = Subject.new
      @result = @subject.get_challenge_questions
    end
    
    it_should_behave_like "Any Request"
    
    it "should set the challenge questions" do
      q = @subject.challenge_questions.detect{|q| q.prompt == 'Which street goes with your address number 840?'}
      q.should_not be_blank
      q.answers.should == ['ROBBIE VW', 'LUBICH DR', 'VICTOR WAY', 'VARSITY CT', 'VAQUERO DR', 'None of the above']
    end
  end
end
